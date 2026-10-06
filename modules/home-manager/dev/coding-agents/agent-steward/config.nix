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
      capabilities = "General-purpose choice for substantial implementation, multi-file refactors, code review, and debugging with defined acceptance criteria. Fits work that requires tracing dependencies, preserving behavior, and iterating on tests. For highly ambiguous problems or tightly interacting architectural constraints, prefer a candidate suited to deeper analysis.";
      thinking_levels = [
        {
          id = "low";
          description = "Localized edits with an explicit solution and straightforward verification";
        }
        {
          id = "medium";
          description = "Implementation following established patterns with a few dependent steps";
        }
        {
          id = "high";
          description = "Multi-file changes, root-cause debugging, or refactors requiring dependency and invariant checks";
        }
        {
          id = "xhigh";
          description = "Competing hypotheses or interacting constraints requiring comparison before implementation";
        }
        {
          id = "max";
          description = "Unusually difficult reasoning where high and xhigh budgets are insufficient; not a default for large tasks";
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
      capabilities = "Choice for ambiguous requirements, difficult root-cause diagnosis, architecture trade-offs, and changes with tightly interacting constraints. Fits unfamiliar problems requiring hypothesis testing, synthesis of conflicting evidence, or careful reasoning across subsystem boundaries. Routine implementation, boilerplate, and task length alone do not require this candidate.";
      thinking_levels = [
        {
          id = "low";
          description = "A narrow judgment or review with supplied evidence and few interacting constraints";
        }
        {
          id = "medium";
          description = "A bounded diagnosis or design decision with clear alternatives and acceptance criteria";
        }
        {
          id = "high";
          description = "Ambiguous diagnosis or architecture work requiring hypothesis testing and cross-subsystem reasoning";
        }
        {
          id = "xhigh";
          description = "Conflicting evidence or tightly coupled constraints requiring sustained comparison of alternatives";
        }
        {
          id = "max";
          description = "Exceptional reasoning difficulty that exceeds lower budgets; not justified by task length alone";
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
      capabilities = "Choice for bounded edits, boilerplate, extraction, summaries, and straightforward questions with clear instructions and supplied context. Fits localized changes with an explicit approach and easy verification. Avoid open-ended diagnosis, architecture decisions, and refactors with broad or unclear dependencies; extra thinking does not remove these scope limits.";
      thinking_levels = [
        {
          id = "low";
          description = "Mechanical edits, extraction, or direct answers from supplied context";
        }
        {
          id = "medium";
          description = "Localized implementation following a known pattern with simple verification";
        }
        {
          id = "high";
          description = "A bounded change requiring edge-case checks or a few dependent reasoning steps";
        }
        {
          id = "xhigh";
          description = "Detailed consistency checks within a clearly defined scope; broader ambiguity calls for another candidate";
        }
        {
          id = "max";
          description = "Exceptional difficulty within a bounded task; not a substitute for a stronger candidate on open-ended work";
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
      capabilities = "General-purpose choice for routine implementation, multi-file changes with clear acceptance criteria, code review, debugging, and synthesis of supplied code or documents. Fits dependency tracing, comparison of evidence, and iteration on tests. For highly ambiguous problems or tightly interacting architectural constraints, prefer a candidate configured for deeper analysis.";
      thinking_levels = [
        {
          id = "low";
          description = "Direct questions, extraction, or localized edits with an explicit approach";
        }
        {
          id = "medium";
          description = "Routine implementation, review, or synthesis with clear acceptance criteria";
        }
        {
          id = "high";
          description = "Debugging or analysis requiring dependency tracing and comparison of evidence";
        }
        {
          id = "xhigh";
          description = "Multi-step analysis with interacting constraints; input length alone does not justify this level";
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
      capabilities = "Choice for straightforward edits, routine implementation, and well-specified coding tasks. Fits established patterns, well-scoped debugging, and edge-case checks with clear verification. For ambiguous root-cause diagnosis or architecture work with tightly interacting constraints, prefer a candidate configured for deeper analysis.";
      thinking_levels = [
        {
          id = "low";
          description = "Mechanical edits or small coding steps with an explicit solution";
        }
        {
          id = "medium";
          description = "Routine implementation using established patterns with a few dependent steps";
        }
        {
          id = "high";
          description = "Well-scoped debugging or implementation requiring edge-case and dependency checks; broader ambiguity calls for another candidate";
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
