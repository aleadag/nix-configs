{
  tools = [
    "pi"
    "agy"
  ];
  accounts = [
    {
      id = "codex-subscription-local";
      source = "codex";
    }
    {
      id = "antigravity-subscription-local";
      source = "antigravity";
    }
  ];
  candidates = [
    {
      id = "sol-pi";
      tool = "pi";
      provider = "openai-codex";
      model = "gpt-6-sol";
      account_id = "codex-subscription-local";
      quota_pool = "primary";
      capabilities = "GPT-6 Sol: complex coding and agentic workflows; text and image input";
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
      account_id = "codex-subscription-local";
      quota_pool = "primary";
      capabilities = "GPT-6 Astra: hardest end-to-end reasoning, coding, research, and document tasks; text and image input";
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
      account_id = "codex-subscription-local";
      quota_pool = "primary";
      capabilities = "GPT-6 Luna: efficient focused, high-volume tasks; text and image input";
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
      id = "gemini-flash-low-agy";
      tool = "agy";
      provider = "google";
      model = "gemini-3.8-flash-low";
      account_id = "antigravity-subscription-local";
      quota_pool = "primary";
      capabilities = "Gemini 3.8 Flash: software engineering and agent workflows; Low variant for straightforward tasks";
      thinking_levels = [
        {
          id = "default";
          description = "Low is encoded in the agy model selector; no separate effort override";
        }
      ];
    }
    {
      id = "gemini-flash-medium-agy";
      tool = "agy";
      provider = "google";
      model = "gemini-3.8-flash-medium";
      account_id = "antigravity-subscription-local";
      quota_pool = "primary";
      capabilities = "Gemini 3.8 Flash: software engineering and agent workflows; Medium variant for routine tasks";
      thinking_levels = [
        {
          id = "default";
          description = "Medium is encoded in the agy model selector; no separate effort override";
        }
      ];
    }
    {
      id = "gemini-flash-high-agy";
      tool = "agy";
      provider = "google";
      model = "gemini-3.8-flash-high";
      account_id = "antigravity-subscription-local";
      quota_pool = "primary";
      capabilities = "Gemini 3.8 Flash: long-horizon software engineering, autonomous agents, and complex workflows; High variant";
      thinking_levels = [
        {
          id = "default";
          description = "High is encoded in the agy model selector; no separate effort override";
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
