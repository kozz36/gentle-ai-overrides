"""Schema-versioned composer target inventories."""
from dataclasses import FrozenInstanceError
import unittest

from composer.agents import ROLES
from composer.profiles import (
    ComposerProfile,
    ProfileError,
    V1_SCHEMA,
    V1_PROFILE,
    V2_PROFILE,
    profile_for_schema,
)


V1_TARGETS = (
    "agents/sdd-apply.md",
    "agents/sdd-archive.md",
    "agents/sdd-design.md",
    "agents/sdd-explore.md",
    "agents/sdd-init.md",
    "agents/sdd-onboard.md",
    "agents/sdd-proposal.md",
    "agents/sdd-research.md",
    "agents/sdd-spec.md",
    "agents/sdd-status.md",
    "agents/sdd-sync.md",
    "agents/sdd-tasks.md",
    "agents/sdd-verify.md",
    "chains/sdd-verify.chain.md",
)
V2_PACKAGE_TARGETS = (
    "assets/agents/gentle-init.md",
    "assets/agents/sdd-init.md",
    "assets/orchestrator-delegation.md",
    "assets/sdd-orchestrator-workflow.md",
)


class ComposerProfileTests(unittest.TestCase):
    def test_v1_target_tuple_is_the_exact_historical_inventory(self):
        self.assertEqual(V1_PROFILE.schema, "deterministic-assets/v1")
        self.assertEqual(V1_PROFILE.targets, V1_TARGETS)
        self.assertEqual(V1_PROFILE.required_targets, V1_TARGETS)
        self.assertEqual(V1_PROFILE.optional_targets, ())
        self.assertEqual(V1_PROFILE.targets, tuple(sorted(
            [f"agents/sdd-{role}.md" for role in ROLES] + ["chains/sdd-verify.chain.md"])))

    def test_v2_inventory_adds_exact_package_targets_and_marks_only_delegation_optional(self):
        self.assertEqual(V2_PROFILE.schema, "deterministic-assets/v2")
        self.assertEqual(V2_PROFILE.targets, tuple(sorted(V1_TARGETS + V2_PACKAGE_TARGETS)))
        self.assertEqual(V2_PROFILE.required_targets, tuple(
            target for target in V2_PROFILE.targets
            if target != "assets/orchestrator-delegation.md"))
        self.assertEqual(V2_PROFILE.optional_targets, ("assets/orchestrator-delegation.md",))

    def test_inventory_invariants_reject_unsafe_unsorted_and_overlapping_targets(self):
        invalid_profiles = (
            (V1_SCHEMA, tuple(reversed(V1_TARGETS)), ()),
            (V1_SCHEMA, ("../unsafe.md",), ()),
            (V1_SCHEMA, ("unsafe\x00.md",), ()),
            (V1_SCHEMA, V1_TARGETS, (V1_TARGETS[0],)),
        )
        for schema, required, optional in invalid_profiles:
            with self.subTest(required=required, optional=optional), self.assertRaises(ProfileError):
                ComposerProfile(schema, required, optional)

    def test_lookup_is_fail_closed_and_profiles_are_immutable(self):
        self.assertIs(profile_for_schema("deterministic-assets/v1"), V1_PROFILE)
        self.assertIs(profile_for_schema("deterministic-assets/v2"), V2_PROFILE)
        for schema in ("deterministic-assets/v3", "", None):
            with self.subTest(schema=schema), self.assertRaises(ProfileError):
                profile_for_schema(schema)
        with self.assertRaises(FrozenInstanceError):
            V2_PROFILE.schema = "deterministic-assets/v3"
        with self.assertRaises(AttributeError):
            V2_PROFILE.targets += ("assets/future.md",)


if __name__ == "__main__":
    unittest.main()
