import * as cheerio from "cheerio";
import express from "express";
import Session from "express-session";
import { generateNonce, SiweErrorType, SiweMessage } from "siwe";
var cors = require("cors");

import db from "./db";

const app = express();
app.use(cors({ credentials: true, origin: "http://localhost:3001" }));
app.use(express.json());
app.use(
  Session({
    name: "sentiment-drips",
    secret: "sentiment-drips-secret",
    resave: true,
    saveUninitialized: true,
    cookie: { secure: false, sameSite: true },
  })
);

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*           SIWE Authentication and Verification           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

app.get("/", (req, res) => {
  res.send("Welcome to Sentiment Drips!");
});

app.get("/nonce", async function (req, res) {
  req.session.nonce = generateNonce();
  res.setHeader("Content-Type", "text/plain");
  res.status(200).send(req.session.nonce);
});

app.post("/verify", async function (req, res) {
  try {
    if (!req.body.message) {
      res
        .status(422)
        .json({ message: "Expected prepareMessage object as body." });
      return;
    }

    let SIWEObject = new SiweMessage(req.body.message);
    const { data: message } = await SIWEObject.verify({
      signature: req.body.signature,
      nonce: req.session.nonce,
    });

    req.session.siwe = message;
    req.session.cookie.expires = new Date(message.expirationTime!);
    req.session.save(() => {
      const query = "SELECT * FROM Users WHERE address = ?";
      const params = [req.session.siwe?.address];

      db.all(query, params, (err, rows) => {
        if (err) {
          res.status(500).json({ error: err.message });
          return;
        }

        res.json(
          rows[0] || {
            name: "",
            address: req.session.siwe?.address,
            avatar: "",
          }
        );
      });
    });
  } catch (e) {
    req.session.siwe = undefined;
    req.session.nonce = undefined;
    console.error(e);
    switch (e) {
      case SiweErrorType.EXPIRED_MESSAGE: {
        const error = e as unknown as Error;
        req.session.save(() =>
          res.status(440).json({ message: error.message })
        );
        break;
      }
      case SiweErrorType.INVALID_SIGNATURE: {
        const error = e as unknown as Error;
        req.session.save(() =>
          res.status(422).json({ message: error.message })
        );
        break;
      }
      default: {
        const error = e as unknown as Error;
        req.session.save(() =>
          res.status(500).json({ message: error.message })
        );
        break;
      }
    }
  }
});

app.get("/logout", (req, res) => {
  req.session.destroy((e) => {
    const error = e as unknown as Error;
    console.log(error);
  });
  res.setHeader("Content-Type", "text/plain");
  res.send(`You have been logged out`);
});

app.get("/verifyAuthentication", function (req, res) {
  if (!req.session.siwe) {
    res.json({
      authenticated: false,
    });
    return;
  }
  const query = "SELECT * FROM Users WHERE address = ?";
  const params = [req.session.siwe?.address];

  db.all(query, params, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(
      { ...(rows[0] as Object), authenticated: true } || {
        name: "",
        address: req.session.siwe?.address,
        avatar: "",
        authenticated: true,
      }
    );
  });
});

app.get("/template", function (req, res) {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }
  console.log("User is authenticated!");
  res.setHeader("Content-Type", "text/plain");
  res.send(
    `You are authenticated and your address is: ${req.session.siwe.address}`
  );
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       User Section                       */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create a new user
app.post("/new-user", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  // Assuming you have a JSON request body with user information
  const { name, avatarUrl } = req.body;

  // Insert the new user into the Users table
  const insertQuery = `
    INSERT INTO Users (name, address, avatarUrl)
    VALUES (?, ?, ?)
  `;

  db.run(
    insertQuery,
    [name, req.session.siwe.address, avatarUrl],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
        console.error(err);
        return;
      }

      res.json({
        message: "User created successfully",
        userId: this.lastID,
      });
    }
  );
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                    Ecosystem Section                     */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create a new ecosystem
app.post("/ecosystem", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  const {
    name,
    logoURL,
    description,
    governanceReady,
    governanceTokenName,
    governanceTokenSymbol,
    governanceTokenAddress,
    timeLockAddress,
    governorAddress,
    createdAt,
  } = req.body;

  const insertQuery = `
    INSERT INTO Ecosystems (createdBy, name, logoURL, description, governanceReady, governanceTokenName, governanceTokenSymbol, governanceTokenAddress, timeLockAddress, governorAddress, createdAt)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.run(
    insertQuery,
    [
      req.session.siwe.address,
      name,
      logoURL,
      description,
      governanceReady,
      governanceTokenName,
      governanceTokenSymbol,
      governanceTokenAddress,
      timeLockAddress,
      governorAddress,
      createdAt,
    ],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
        console.log(err);
        return;
      }

      res.json({
        message: "ecosystem created successfully",
        ecosystemId: this.lastID,
      });
    }
  );
});

// Read a single ecosystem filtered by ID
app.get("/ecosystem/:ecosystemId", (req, res) => {
  const { ecosystemId } = req.params;
  const selectQuery = `
    SELECT * FROM Ecosystems
    WHERE ecosystemId = ?
  `;

  db.get(selectQuery, [ecosystemId], (err, ecosystem) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    if (!ecosystem) {
      res.status(404).json({ message: "ecosystem not found" });
      return;
    }

    res.json(ecosystem);
  });
});

// Read all ecosystems with optional filtering by creator userId
app.get("/ecosystem", (req, res) => {
  const { userId } = req.query;

  const query = userId
    ? "SELECT * FROM Ecosystems WHERE createdBy = ?"
    : "SELECT * FROM Ecosystems";
  const params = userId ? [userId] : [];

  db.all(query, params, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(rows);
  });
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                     EcoFunds Section                     */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create a new ecoFund
app.post("/eco-funds", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  const {
    ecoFundProposalId,
    ecosystemId,
    emoji,
    title,
    description,
    strategyAddress,
    createdAt,
  } = req.body;

  const insertQuery = `
    INSERT INTO EcoFunds (createdBy, proposalPassed, ecoFundProposalId, allocationProposalId, ecosystemId, emoji, title, description, strategyAddress, createdAt)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.run(
    insertQuery,
    [
      req.session.siwe.address,
      false,
      ecoFundProposalId,
      "",
      ecosystemId,
      emoji,
      title,
      description,
      strategyAddress,
      createdAt,
    ],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
        console.log(err);
        return;
      }

      res.json({
        message: "ecoFund created successfully",
        ecoFundId: this.lastID,
      });
    }
  );
});

// Read a single ecoFund filtered by ID
app.get("/eco-funds/:ecoFundId", (req, res) => {
  const { ecoFundId } = req.params;

  const selectQuery = `
    SELECT * FROM EcoFunds
    WHERE ecoFundId = ?
  `;

  db.get(selectQuery, [ecoFundId], (err, ecoFund) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    if (!ecoFund) {
      res.status(404).json({ message: "ecoFund not found" });
      return;
    }

    res.json(ecoFund);
  });
});

// Read all ecoFunds with optional filtering by ecosystemId
app.get("/eco-funds", (req, res) => {
  const { ecosystemId } = req.query;

  const query = ecosystemId
    ? "SELECT * FROM EcoFunds WHERE ecosystemId = ?"
    : "SELECT * FROM EcoFunds";
  const params = ecosystemId ? [ecosystemId] : [];

  db.all(query, params, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(rows);
  });
});

// TODO: Verify ecoFund proposal pass.
// Get the pool id from the person who last calls the time lock
// Validate with isPoolAdmin that poolId is created by timeLock
// Validate that getStrategy when passed poolId gives strategy
// Flag proposalPassed to true

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                     Projects Section                     */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create a new project
app.post("/projects", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  const { tokensRequested, emoji, title, description } = req.body;
  const insertQuery = `
    INSERT INTO Projects (createdBy, tokensRequested, emoji, title, description)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.run(
    insertQuery,
    [req.session.siwe.address, tokensRequested, emoji, title, description],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }

      res.json({
        message: "Project created successfully",
        projectId: this.lastID,
      });
    }
  );
});

// Read a single project filtered by ID
app.get("/projects/:projectId", (req, res) => {
  const { projectId } = req.params;

  const selectQuery = `
    SELECT * FROM Projects
    WHERE projectId = ?
  `;

  db.get(selectQuery, [projectId], (err, project) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    if (!project) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    res.json(project);
  });
});

// Read all projects with optional filtering by user
app.get("/projects", (req, res) => {
  const { userId } = req.query;

  const query = userId
    ? "SELECT * FROM Projects WHERE createdBy = ?"
    : "SELECT * FROM Projects";
  const params = userId ? [userId] : [];

  db.all(query, params, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(rows);
  });
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                     Showcase Section                     */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create a new showcase
app.post("/showcase/:ecoFundId/:projectId", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  const { ecoFundId } = req.params;
  const { projectId, recipientId, status } = req.body;

  const insertQuery = `
    INSERT INTO ShowcasedProjects (ecoFundId, projectId,  recipientId, status)
    VALUES (?, ?, ?, ?)
  `;

  db.run(
    insertQuery,
    [ecoFundId, projectId, recipientId, status],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }

      res.json({ message: "Project added to showcased projects successfully" });
    }
  );
});

// Read all showcased project under an ecoFund
app.get("/showcase/:ecoFundId", (req, res) => {
  const { ecoFundId } = req.params;
  const selectQuery = `
    SELECT P.*
    FROM Projects P
    INNER JOIN ShowcasedProjects SP ON P.projectId = SP.projectId
    WHERE SP.ecoFundId = ${ecoFundId}
  `;

  db.all(selectQuery, (err, projects) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(projects);
  });
});

// TODO: Verify accepted showcases projects

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                    Allocation Section                    */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Create and edit allocations under an ecoFund (expects an array of allocations)
app.put("/allocate/:ecoFundId", (req, res) => {
  if (!req.session.siwe) {
    res.status(401).json({ message: "You have to first sign_in" });
    return;
  }

  const { ecoFundId } = req.params;
  const allocations: { amount: number; projectId: string }[] = req.body; // Expecting an array of allocation objects

  if (!Array.isArray(allocations)) {
    res.status(400).json({
      error: "Invalid request body format. Expected an array of allocations.",
    });
    return;
  }

  // Calculate the total amount of all allocations
  const totalAllocation = allocations.reduce((total, allocation) => {
    return total + parseFloat(allocation.amount as any);
  }, 0);

  // Check if the total allocation exceeds the ecoFund's tokenAmount
  const checkQuery = `SELECT tokenAmount FROM EcoFunds WHERE ecoFundId = ${ecoFundId}`;
  db.get(checkQuery, (err, ecoFund: any) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    if (!ecoFund) {
      res.status(404).json({ error: "ecoFund not found" });
      console.log("err2");

      return;
    }

    if (totalAllocation > ecoFund.tokenAmount) {
      res
        .status(400)
        .json({ error: "Total allocation exceeds ecoFund tokenAmount" });
      return;
    }

    const sql = `
    INSERT INTO AllocatedProjects (allocatedBy, ecoFundId, projectId, amount)
    VALUES (?, ?, ?, ?)
    ON CONFLICT (allocatedBy, ecoFundId, projectId)
    DO UPDATE SET amount = excluded.amount
    `;

    // Begin a transaction
    db.serialize(() => {
      db.run("BEGIN TRANSACTION");

      try {
        allocations.forEach((allocation) => {
          const { projectId, amount } = allocation;
          db.run(sql, [
            req.session.siwe?.address,
            ecoFundId,
            projectId,
            amount,
          ]);
        });

        // Commit the transaction if all insertions are successful
        db.run("COMMIT");
        res.json({ message: "Allocations updated successfully!" });
      } catch (error) {
        // Rollback the transaction if there's an error
        db.run("ROLLBACK");
        console.error("Transaction rolled back due to an error:", error);
        res.status(500).json({ error });
      }
    });
  });
});

// Read all allocators and their allocations under a specific ecoFund
app.get("/allocate/:ecoFundId", (req, res) => {
  const { ecoFundId } = req.params;
  const selectQuery = `
    SELECT U.name AS allocatorName, U.address AS allocatorAddress,
           AP.projectId AS allocatedProjectId, AP.amount AS allocationAmount,
           P.title AS projectTitle, P.createdBy AS projectCreatedBy
    FROM AllocatedProjects AP
    INNER JOIN Users U ON AP.allocatedBy = U.address
    INNER JOIN Projects P ON AP.projectId = P.projectId
    WHERE AP.ecoFundId = ${ecoFundId}
  `;

  db.all(selectQuery, (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    console.log(results);

    // Organize the results into the desired JSON structure
    const allocatorsMap = new Map(); // Map to group allocators and their allocations
    results.forEach((row) => {
      const {
        allocatorName,
        allocatorAddress,
        allocatedProjectId,
        allocationAmount,
        projectTitle,
        projectCreatedBy,
      } = row as any;

      if (!allocatorsMap.has(allocatorName)) {
        // Create a new allocator entry if it doesn't exist in the map
        allocatorsMap.set(allocatorName, {
          name: allocatorName,
          address: allocatorAddress,
          allocated: [],
        });
      }

      // Add allocation details to the allocator's allocated array
      const allocator = allocatorsMap.get(allocatorName);
      allocator.allocated.push({
        projectId: allocatedProjectId,
        amount: allocationAmount,
        title: projectTitle,
        createdBy: projectCreatedBy,
      });
    });

    // Convert the map values to an array to match the specified signature
    const allocatorsArray = Array.from(allocatorsMap.values());

    res.json(allocatorsArray);
  });
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       Table Helper                       */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Custom function to edit table content regardless of the frontend
app.post("/edit-table", (req, res) => {
  let query = `DROP TABLE table_name`;

  db.all(query, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(rows);
  });
});

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                  EditorJS Link Previewer                  */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

app.get("/fetchUrl", async (req, res) => {
  let url = req.query.url as string;
  let resHTML = await fetch(new URL(url)).catch((e) => console.log(e));

  if (!resHTML) {
    res.status(500).json({
      success: 0,
      meta: {},
    });
    return;
  }

  const html = await resHTML.text();
  const $ = cheerio.load(html);

  // custom meta-tag function
  const getMetaTag = (value: string) => {
    return (
      $(`meta[name=${value}]`).attr("content") ||
      $(`meta[property="og:${value}"]`).attr("content") ||
      $(`meta[property="twitter:${value}"]`).attr("content")
    );
  };

  const metadataObject = {
    success: 1,
    meta: {
      title: $("title").first().text(),
      description: getMetaTag("description"),
      image: {
        url: getMetaTag("image"),
      },
    },
  };
  res.send(metadataObject);
  return;
});

module.exports = app;

declare module "express-session" {
  interface SessionData {
    nonce: string;
    siwe: SiweMessage;
  }
}
