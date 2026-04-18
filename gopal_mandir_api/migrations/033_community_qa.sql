-- Community Q&A forum.
-- Anyone can post a question and like. Only admins can post answers
-- and comments on answers.

CREATE TABLE IF NOT EXISTS community_posts (
    id SERIAL PRIMARY KEY,
    author_name VARCHAR(200) NOT NULL,
    author_phone VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    title VARCHAR(300) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'visible',
    likes_count INTEGER NOT NULL DEFAULT 0,
    answers_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_posts_status_created
    ON community_posts(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_posts_status_likes
    ON community_posts(status, likes_count DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_posts_status_answers
    ON community_posts(status, answers_count DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_posts_category_created
    ON community_posts(category, created_at DESC);

CREATE TABLE IF NOT EXISTS community_answers (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    author_admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    author_name VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_answers_post_created
    ON community_answers(post_id, created_at DESC);

CREATE TABLE IF NOT EXISTS community_answer_comments (
    id SERIAL PRIMARY KEY,
    answer_id INTEGER NOT NULL REFERENCES community_answers(id) ON DELETE CASCADE,
    author_admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    author_name VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_answer_comments_answer_created
    ON community_answer_comments(answer_id, created_at ASC);

CREATE TABLE IF NOT EXISTS community_post_likes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_post_likes_post
    ON community_post_likes(post_id);

CREATE TABLE IF NOT EXISTS community_answer_likes (
    id SERIAL PRIMARY KEY,
    answer_id INTEGER NOT NULL REFERENCES community_answers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_answer_likes_answer
    ON community_answer_likes(answer_id);
