{
  tools = [
    "pi"
    "agy"
  ];
  candidates = [
    {
      id = "sol-pi";
      tool = "pi";
      provider = "openai-codex";
      model = "gpt-6.1-sol";
      quota_bucket = "pi_codex";
      quota_pool = "primary";
      cost = 20;
      capabilities = "Near-flagship complex reasoning and coding at lower cost. Use for substantial multi-file coding, refactors, and agent workflows when gpt-6-luna is too weak and gpt-6-astra is too expensive. Text and image in, tools.";
      thinking_levels = [
        {
          id = "low";
          description = "Brief reasoning for straightforward coding tasks";
        }
        {
          id = "medium";
          description = "Balanced reasoning for routine coding and agent work";
        }
        {
          id = "high";
          description = "Deeper reasoning for complex coding and agent workflows";
        }
        {
          id = "xhigh";
          description = "Extended reasoning for difficult multi-step coding tasks";
        }
        {
          id = "max";
          description = "Maximum reasoning for the hardest coding and agent tasks";
        }
      ];
    }
    {
      id = "astra-pi";
      tool = "pi";
      provider = "openai-codex";
      model = "gpt-6-astra";
      quota_bucket = "pi_codex";
      quota_pool = "primary";
      cost = 100;
      capabilities = "Most capable GPT-6 for the most demanding reasoning, architecture, research, and long coding agents. Use only when gpt-6.1-sol is likely to fail. Text and image in, tools. Do not use for routine or high-volume work.";
      thinking_levels = [
        {
          id = "low";
          description = "Brief reasoning when a capable model is useful but the task is simple";
        }
        {
          id = "medium";
          description = "Balanced reasoning for substantial tasks";
        }
        {
          id = "high";
          description = "Deeper reasoning for complex end-to-end work";
        }
        {
          id = "xhigh";
          description = "Extended reasoning for very difficult multi-step work";
        }
        {
          id = "max";
          description = "Maximum reasoning for the hardest end-to-end tasks";
        }
      ];
    }
    {
      id = "luna-pi";
      tool = "pi";
      provider = "openai-codex";
      model = "gpt-6-luna";
      quota_bucket = "pi_codex";
      quota_pool = "primary";
      cost = 1;
      capabilities = "Most efficient GPT-6 for focused, cost-sensitive, high-volume work. Use for small edits, boilerplate, simple questions, and narrow tasks. Weakest GPT-6 here; do not use for hard multi-step reasoning or large refactors.";
      thinking_levels = [
        {
          id = "low";
          description = "Brief reasoning for simple focused tasks";
        }
        {
          id = "medium";
          description = "Balanced reasoning for routine focused tasks";
        }
        {
          id = "high";
          description = "Deeper reasoning for demanding focused tasks";
        }
        {
          id = "xhigh";
          description = "Extended reasoning when the focused task is unusually difficult";
        }
        {
          id = "max";
          description = "Maximum reasoning for the hardest focused tasks";
        }
      ];
    }
    {
      id = "grok-4.6-pi";
      tool = "pi";
      provider = "xai";
      model = "grok-4.6";
      quota_bucket = "pi_xai";
      quota_pool = "primary";
      cost = 13;
      capabilities = "Frontier model for coding, agentic tasks, and knowledge work. Text and image in, 500k context, function calling, structured outputs, and reasoning. Use for large-context coding and knowledge work. Not a GPT-6 substitute.";
      thinking_levels = [
        {
          id = "low";
          description = "Brief reasoning for straightforward tasks";
        }
        {
          id = "medium";
          description = "Balanced reasoning for routine work";
        }
        {
          id = "high";
          description = "Deeper reasoning for complex work";
        }
        {
          id = "xhigh";
          description = "Extended reasoning for difficult multi-step work";
        }
      ];
    }
    {
      id = "gemini-flash-agy";
      tool = "agy";
      provider = "google";
      model = "gemini-3.8-flash";
      quota_bucket = "antigravity";
      quota_pool = "gemini";
      cost = 8;
      capabilities = "Fast flash model for straightforward edits, routine coding, and agent workflows on Antigravity quota. Still a flash model, not gpt-6-astra / gpt-6.1-sol hard reasoning.";
      thinking_levels = [
        {
          id = "low";
          description = "Brief reasoning for straightforward edits and small agent steps";
        }
        {
          id = "medium";
          description = "Balanced reasoning for routine coding and typical agent workflows";
        }
        {
          id = "high";
          description = "Deeper reasoning for longer software-engineering and agent runs";
        }
      ];
    }
  ];
  jev.model = "jev-1.13.0";
  thresholds = {
    risky = 0.6;
    choiceConfidence = 0.45;
  };
}
