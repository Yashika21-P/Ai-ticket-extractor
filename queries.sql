-- AI Ticket Extractor: SQL analysis in BigQuery
-- Tables: tests (60 rows, one per test message) and failures (38 rows, one per wrong field)
-- Replace YOUR_PROJECT_ID with your own BigQuery project ID before running.

-- Query 1: accuracy by case type (normal vs hard)
SELECT case_type,
  ROUND(AVG(issue_ok), 2) AS issue_acc,
  ROUND(AVG(order_ok), 2) AS order_acc,
  ROUND(AVG(urgency_ok), 2) AS urgency_acc,
  ROUND(AVG(sentiment_ok), 2) AS sentiment_acc,
  ROUND(AVG(escalate_ok), 2) AS escalate_acc
FROM `YOUR_PROJECT_ID.ticket_data.tests`
GROUP BY case_type;

-- Query 2: most common failure types
SELECT failure_type, COUNT(*) AS n
FROM `YOUR_PROJECT_ID.ticket_data.failures`
GROUP BY failure_type
ORDER BY n DESC;

-- Query 3: the ten worst messages (most wrong fields)
SELECT id, message,
  5 - (issue_ok + order_ok + urgency_ok + sentiment_ok + escalate_ok) AS fields_wrong
FROM `YOUR_PROJECT_ID.ticket_data.tests`
WHERE 5 - (issue_ok + order_ok + urgency_ok + sentiment_ok + escalate_ok) > 0
ORDER BY fields_wrong DESC
LIMIT 10;

-- Query 4: failures with their messages (a join)
SELECT f.msg_id, f.field, f.expected, f.got, f.failure_type, t.message
FROM `YOUR_PROJECT_ID.ticket_data.failures` AS f
JOIN `YOUR_PROJECT_ID.ticket_data.tests` AS t
  ON f.msg_id = t.id
ORDER BY f.failure_type, f.msg_id;

-- Query 5: rank the worst messages within each case type (a CTE and a window function)
WITH wrong AS (
  SELECT id, case_type,
    5 - (issue_ok + order_ok + urgency_ok + sentiment_ok + escalate_ok) AS fields_wrong
  FROM `YOUR_PROJECT_ID.ticket_data.tests`
)
SELECT id, case_type, fields_wrong,
  RANK() OVER (PARTITION BY case_type ORDER BY fields_wrong DESC) AS rank_in_case
FROM wrong
WHERE fields_wrong > 0
ORDER BY case_type, rank_in_case;
