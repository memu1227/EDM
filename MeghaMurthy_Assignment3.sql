Use BaseBall_Summer_2023;
IF OBJECT_ID (N'dbo.[Parks]', N'U') IS NOT NULL
    DROP TABLE dbo.[Parks];

GO
CREATE TABLE Parks(
    parkID VARCHAR(255) NOT NULL,
    parkName VARCHAR(255),
    alias VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255)
);

ALTER TABLE Parks
    ADD CONSTRAINT Parks_PK PRIMARY KEY (parkID);

ALTER TABLE Parks
    ADD CONSTRAINT check_Country CHECK (country in ('AU', 'CA', 'JP', 'MX', 'PR', 'UK', 'US'));

