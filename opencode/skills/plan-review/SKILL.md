---
name: plan-review
description: >
  This skill should be used when users ask for a plan review, pre-execution critique,
  plan-quality assurance, YAGNI/scope creep checks, or when oracle needs PASS / REVISE / REJECT decisions.
---

# Plan Review

Review an implementation plan **before execution**. Focus on identifying quality risks, missing context, and unnecessary complexity. Do not rewrite the whole plan.

## Required Output

Start with exactly one verdict:
- PASS
- REVISE
- REJECT

Use PASS only when the plan is clear, minimal, safe, and executable.

## Review Checklist

- goal clarity: Is the objective unambiguous and measurable?
- assumptions: Are assumptions explicit and testable?
- scope definition: What is in scope and what is explicitly out of scope?
- affected files/systems: Are impacted modules, interfaces, and dependencies identified?
- implementation sequence: Are dependencies and ordering safe and realistic?
- acceptance criteria: Are success/failure conditions concrete?
- validation strategy: Is there a practical way to verify behavior changes?
- risks and rollback: Are rollback points, blast radius, and failure modes documented?
- YAGNI / overengineering: Are there unnecessary features, steps, or abstractions?

## Response Rules

- Do not implement code.
- Do not rewrite or expand the entire plan.
- Do not browse external documentation unless the gap is required to judge plan validity.
- Flag only missing or high-risk items and request fixes when output is REVISE or REJECT.
- Keep feedback concise and action-oriented.

## Escalation Criteria

Recommend REVISE or REJECT when you find:
- unclear goals or acceptance criteria
- scope creep or mixed priorities
- hidden dependencies not accounted for
- missing validation or impossible rollback
- violation of YAGNI / overengineering concerns
