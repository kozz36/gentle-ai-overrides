"""The planner records decisions without authorizing or applying writes."""
import unittest

from composer.planner import PlanError, plan_asset

A, B, C = "a" * 64, "b" * 64, "c" * 64


def observation(digest, owner="user-owned", tools=("read",)):
    return {"sha256": digest, "ownership": owner, "tools": list(tools) if tools is not None else None}


def desired(digest, tools=("read",)):
    return {"sha256": digest, "tools": list(tools) if tools is not None else None}


class PlannerTests(unittest.TestCase):
    def check(self, base, installed, new, action, reason):
        row = plan_asset("agents/sdd-apply.md", base, installed, new)
        self.assertEqual((row["action"], row["reason"]), (action, reason))
        self.assertEqual(row["desired_sha256"], new["sha256"])
        return row

    def test_already_matching_content_needs_no_write(self):
        self.check(observation(A), observation(B), desired(B), "noop", "already_matches")

    def test_unchanged_installed_baseline_can_propose_update(self):
        self.check(observation(A), observation(A), desired(B), "propose", "baseline_matches")

    def test_local_drift_is_not_overwritten(self):
        self.check(observation(A), observation(B), desired(C), "blocked", "local_drift")

    def test_unchanged_desired_content_does_not_hide_installed_drift(self):
        self.check(observation(A), observation(B), desired(A), "blocked", "local_drift")

    def test_missing_baseline_only_allows_a_no_write_result(self):
        self.check(None, observation(A), desired(A), "noop", "already_matches")
        self.check(None, observation(A), desired(B), "blocked", "baseline_required")

    def test_missing_installed_target_is_not_created(self):
        self.check(None, None, desired(A), "blocked", "missing_installed_target")

    def test_all_digest_relations_follow_the_three_way_rule(self):
        for base in (A, B, C):
            for installed in (A, B, C):
                for new in (A, B, C):
                    action = "noop" if installed == new else "propose" if installed == base else "blocked"
                    row = plan_asset("target", observation(base), observation(installed), desired(new))
                    self.assertEqual(row["action"], action, (base, installed, new))

    def test_ownership_conflicts_take_precedence_over_matching_bytes(self):
        for owner in ("managed", "unknown"):
            self.check(observation(A), observation(A, owner), desired(A), "blocked", "unsupported_ownership")
            self.check(observation(A, owner), observation(A), desired(A), "blocked", "ownership_changed")

    def test_tool_changes_are_not_inferred_or_unioned(self):
        self.check(observation(A), observation(A), desired(B, ("read", "bash")),
                   "blocked", "tool_contract_changed")
        self.check(observation(A), observation(B, tools=("bash",)), desired(A),
                   "blocked", "tool_contract_changed")
        self.check(observation(A), observation(B, tools=("bash",)), desired(B, ("bash",)),
                   "blocked", "tool_contract_changed")

    def test_missing_baseline_cannot_hide_conflicting_tool_observations(self):
        self.check(None, observation(A, tools=("bash",)), desired(A), "blocked", "tool_contract_changed")

    def test_chains_have_explicitly_absent_tool_contracts(self):
        row = plan_asset("chains/sdd-verify.chain.md", observation(A, tools=None),
                         observation(A, tools=None), desired(B, tools=None))
        self.assertEqual(row["action"], "propose")

    def test_invalid_observations_fail_before_a_plan_is_emitted(self):
        for change in ({"sha256": "SHA256:" + A}, {"sha256": 1}, {"tools": []},
                       {"tools": ["read", "read"]}, {"tools": [None]},
                       {"ownership": "adopted"}, {"ownership": []}, {"extra": True}):
            with self.subTest(change=change), self.assertRaises(PlanError):
                plan_asset("target", None, dict(observation(A), **change), desired(B))
        with self.assertRaises(PlanError):
            plan_asset("target", None, observation(A), {"sha256": B})

    def test_results_are_stable_and_do_not_mutate_observations(self):
        import copy
        inputs = (observation(A), observation(A), desired(B))
        before = copy.deepcopy(inputs)
        first = plan_asset("target", *inputs)
        self.assertEqual(first, plan_asset("target", *inputs))
        self.assertEqual(inputs, before)
        self.assertEqual(first["baseline_sha256"], A)
        self.assertEqual(first["installed_ownership"], "user-owned")


if __name__ == "__main__":

    unittest.main()
