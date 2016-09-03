-- 1 up
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER        PRIMARY KEY AUTOINCREMENT,
    username        VARCHAR(255),
    email           VARCHAR(255),
    password        VARCHAR(255),
    password_legacy VARCHAR(255),
    realname        VARCHAR(255),
    phone           VARCHAR(255),
    verified        INTEGER DEFAULT 0,
    admin           INTEGER DEFAULT 0
);

-- 1 down
DROP TABLE IF EXISTS users;
