-- Table for users
CREATE TABLE Users (
    userId INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    avatarUrl TEXT NOT NULL
);

-- Table for Ecosystems
CREATE TABLE Ecosystems (
    ecosystemId INTEGER PRIMARY KEY,
    createdBy TEXT NOT NULL,
    name TEXT NOT NULL,
    logoURL TEXT NOT NULL,
    description TEXT NOT NULL,
    governanceReady BOOLEAN NOT NULL,
    governanceTokenName TEXT NOT NULL,
    governanceTokenSymbol TEXT NOT NULL,
    governanceTokenAddress TEXT NOT NULL,
    timeLockAddress TEXT NOT NULL,
    governorAddress TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (createdBy) REFERENCES Users(address)
);

-- Table for EcoFunds
CREATE TABLE EcoFunds (
    ecoFundId INTEGER PRIMARY KEY,
    createdBy TEXT NOT NULL,
    proposalPassed BOOLEAN NOT NULL,
    ecoFundProposalId TEXT NOT NULL,
    allocationProposalId TEXT NOT NULL,
    ecosystemId INTEGER NOT NULL,
    emoji TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    strategyAddress TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (createdBy) REFERENCES Users(address),
    FOREIGN KEY (ecosystemId) REFERENCES Ecosystems(ecosystemId)
);

-- Table for allocated projects within allocators
CREATE TABLE AllocatedProjects (
    allocationId INTEGER PRIMARY KEY,
    allocatedBy TEXT NOT NULL,
    ecoFundId INTEGER NOT NULL,
    projectId INTEGER NOT NULL,
    amount REAL NOT NULL,
    FOREIGN KEY (allocatedBy) REFERENCES Users(address),
    FOREIGN KEY (ecoFundId) REFERENCES EcoFunds(ecoFundId),
    FOREIGN KEY (projectId) REFERENCES Projects(projectId),
    UNIQUE (allocatedBy, ecoFundId, projectId)
);

-- Table for projects
CREATE TABLE Projects (
    projectId INTEGER PRIMARY KEY,
    createdBy TEXT NOT NULL,
    tokensRequested REAL NOT NULL,
    emoji TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    FOREIGN KEY (createdBy) REFERENCES Users(address)
);

-- Table for projects showcase
-- /// @notice The Status enum that all recipients are based from
-- enum Status {
--     None,
--     Pending,
--     Accepted,
--     Rejected,
--     Appealed,
--     InReview,
--     Canceled
-- }
CREATE TABLE ShowcasedProjects (
    showcaseId INTEGER PRIMARY KEY,
    ecoFundId INTEGER NOT NULL,
    projectId INTEGER NOT NULL,
    recipientId TEXT NOT NULL,
    status INTEGER NOT NULL,
    FOREIGN KEY (ecoFundId) REFERENCES EcoFunds(ecoFundId),
    FOREIGN KEY (projectId) REFERENCES Projects(projectId)
);