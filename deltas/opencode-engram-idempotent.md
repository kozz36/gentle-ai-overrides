<!-- shape:block -->
    "experimental.chat.system.transform": async (input, output) => {
      const hasMemoryProtocol = output.system.some(
        (entry) =>
          entry.includes("<!-- gentle-ai:engram-protocol -->") ||
          entry.includes("## Engram Persistent Memory — Protocol"),
      )

      if (!hasMemoryProtocol) {
        if (output.system.length > 0) {
          output.system[output.system.length - 1] += "\n\n" + MEMORY_INSTRUCTIONS
        } else {
          output.system.push(MEMORY_INSTRUCTIONS)
        }
      }
<!-- /shape:block -->
