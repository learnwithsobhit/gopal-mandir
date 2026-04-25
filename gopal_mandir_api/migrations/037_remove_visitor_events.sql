-- Remove visitor screen analytics (feature retired). Safe if table never existed.
DROP TABLE IF EXISTS visitor_events;
