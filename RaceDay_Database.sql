/* ============================================================
   RaceDay Database Script
   PROG6212 - Part 1, Section C
   ============================================================ */
CREATE DATABASE RaceDayDB;

USE RaceDayDB;

/* ============================================================
   TABLE: Users
   Stores both Organisers and Participants, distinguished by Role.
   ============================================================ */
CREATE TABLE Users (
    UserId              INT IDENTITY(1,1) PRIMARY KEY,
    FirstName           VARCHAR(50)   NOT NULL,
    LastName            VARCHAR(50)   NOT NULL,
    Email               VARCHAR(100)  NOT NULL,
    PasswordHash        VARCHAR(255)  NOT NULL,
    PhoneNumber         VARCHAR(20)   NULL,
    Role                VARCHAR(20)   NOT NULL,
    ProfilePictureUrl   VARCHAR(255)  NULL,
    CreatedAt           DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Role CHECK (Role IN ('Organiser', 'Participant'))
);

/* ============================================================
   TABLE: Sessions
   Tracks server-side session tokens issued at login.
   ============================================================ */
CREATE TABLE Sessions (
    SessionId       INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT            NOT NULL,
    SessionToken    NVARCHAR(255)  NOT NULL,
    CreatedAt       DATETIME       NOT NULL DEFAULT GETDATE(),
    ExpiresAt       DATETIME       NOT NULL,
    CONSTRAINT UQ_Sessions_Token UNIQUE (SessionToken),
    CONSTRAINT FK_Sessions_Users FOREIGN KEY (UserId)
        REFERENCES Users(UserId) ON DELETE CASCADE
);

/* ============================================================
   TABLE: Events
   Created and owned by an Organiser.
   ============================================================ */
CREATE TABLE Events (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT             NOT NULL,
    Name            VARCHAR(100)   NOT NULL,
    Description     VARCHAR(1000)  NULL,
    EventDate       DATETIME        NOT NULL,
    Location        VARCHAR(150)   NOT NULL,
    DistanceKm      DECIMAL(5,2)    NOT NULL,
    EventType       VARCHAR(20)    NOT NULL,
    BannerImageUrl  VARCHAR(255)   NULL,
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_Events_Type CHECK (EventType IN ('Run', 'Walk', 'Cycle')),
    CONSTRAINT CK_Events_Distance CHECK (DistanceKm > 0),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserId)
        REFERENCES Users(UserId)
);

/* ============================================================
   TABLE: Categories
   Age or distance categories that belong to a single event.
   ============================================================ */
CREATE TABLE Categories (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT             NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    MinAge          INT             NULL,
    MaxAge          INT             NULL,
    DistanceKm      DECIMAL(5,2)    NULL,
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId)
        REFERENCES Events(EventId) ON DELETE CASCADE
);

/* ============================================================
   TABLE: Enrolments
   Links a Participant to an Event under a chosen Category.
   A participant may enrol in a given event only once.
   ============================================================ */
CREATE TABLE Enrolments (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT             NOT NULL,
    EventId         INT             NOT NULL,
    CategoryId      INT             NOT NULL,
    EnrolmentDate   DATETIME        NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Pending',
    CONSTRAINT CK_Enrolments_Status CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    CONSTRAINT UQ_Enrolments_ParticipantEvent UNIQUE (ParticipantId, EventId),
    CONSTRAINT FK_Enrolments_Users FOREIGN KEY (ParticipantId)
        REFERENCES Users(UserId),
    CONSTRAINT FK_Enrolments_Events FOREIGN KEY (EventId)
        REFERENCES Events(EventId),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryId)
        REFERENCES Categories(CategoryId)
);

/* ============================================================
   TABLE: Results
   One result per enrolment, captured by the owning Organiser.
   ============================================================ */
CREATE TABLE Results (
    ResultId                INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId             INT         NOT NULL,
    CapturedByOrganiserId   INT         NOT NULL,
    FinishTime              TIME        NULL,
    FinishPosition          INT         NULL,
    TotalFinishers          INT         NULL,
    CapturedDate            DATETIME    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_Results_Enrolment UNIQUE (EnrolmentId),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentId)
        REFERENCES Enrolments(EnrolmentId) ON DELETE CASCADE,
    CONSTRAINT FK_Results_Organiser FOREIGN KEY (CapturedByOrganiserId)
        REFERENCES Users(UserId)
);

/* ============================================================
   SEED DATA
   ============================================================ */

-- Organisers (2) and Participants (2)
INSERT INTO Users (FirstName, LastName, Email, PasswordHash, PhoneNumber, Role) VALUES
('Naledi', 'Khumalo', 'naledi.khumalo@raceday.co.za', 'HASHED_PLACEHOLDER_1', '0821234567', 'Organiser'),
('Pieter', 'van Wyk', 'pieter.vanwyk@raceday.co.za', 'HASHED_PLACEHOLDER_2', '0827654321', 'Organiser'),
('Thandiwe', 'Mokoena', 'thandiwe.mokoena@gmail.com', 'HASHED_PLACEHOLDER_3', '0831112222', 'Participant'),
('Ryan', 'Naidoo', 'ryan.naidoo@gmail.com', 'HASHED_PLACEHOLDER_4', '0833334444', 'Participant');

-- Events (3), each owned by an Organiser
INSERT INTO Events (OrganiserId, Name, Description, EventDate, Location, DistanceKm, EventType) VALUES
(1, 'Johannesburg City Run', 'An annual road run through the streets of Johannesburg CBD.', '2026-11-08 06:00:00', 'Johannesburg, Gauteng', 21.10, 'Run'),
(1, 'Soweto Community Walk', 'A family-friendly charity walk supporting local schools.', '2026-09-27 07:00:00', 'Soweto, Gauteng', 5.00, 'Walk'),
(2, 'Cape Winelands Cycle Tour', 'A scenic cycling tour through the Cape Winelands.', '2026-10-18 06:30:00', 'Stellenbosch, Western Cape', 94.70, 'Cycle');

-- Categories for each event
INSERT INTO Categories (EventId, Name, MinAge, MaxAge, DistanceKm) VALUES
(1, '21km Half Marathon', 18, 99, 21.10),
(1, '10km Fun Run', 12, 99, 10.00),
(2, 'Family 5km', 0, 99, 5.00),
(3, '94.7km Ultra', 18, 99, 94.70),
(3, '45km Half Tour', 16, 99, 45.00);

-- Sample enrolments
INSERT INTO Enrolments (ParticipantId, EventId, CategoryId, Status) VALUES
(3, 1, 1, 'Confirmed'),
(4, 1, 2, 'Pending'),
(3, 3, 4, 'Confirmed');

-- Sample result for a completed enrolment
INSERT INTO Results (EnrolmentId, CapturedByOrganiserId, FinishTime, FinishPosition, TotalFinishers) VALUES
(1, 1, '01:45:32', 47, 312);

/* ============================================================
   VERIFICATION QUERIES (optional - run manually to check seed data)
   ============================================================ */
SELECT * FROM Users;
SELECT * FROM Events;
SELECT * FROM Categories;
SELECT * FROM Enrolments;
SELECT * FROM Results;

