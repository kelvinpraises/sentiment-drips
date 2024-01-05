export interface User {
  name: string;
  avatarUrl: string;
}

export interface Project {
  tokensRequested: number;
  emoji: string;
  title: string;
  description: string;
}

export interface EcoFund {
  emoji: string;
  title: string;
  tokenAmount: number;
  description: string;
  registrationEnd: number;
  allocationEnd: number;
  createdAt: number;
}

export interface Allocation {
  amount: number;
  projectId: number;
}

export const BACKEND_ADDR = "http://localhost:3002";

export const createUser = async (user: User, callback: () => void) => {
  const res = await fetch(`${BACKEND_ADDR}/new-user`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(user),
    credentials: "include",
  });

  if ((await res.json()).userId) {
    callback();
  }
};

export const getEcoFunds = async (userId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds?userId=${userId}`,
    {
      credentials: "include",
    }
  );
  return await res.json();
};

export const getProjects = async (userId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-projects?userId=${userId}`,
    {
      credentials: "include",
    }
  );

  return await res.json();
};

export const createProject = async (
  project: Project,
  callback: (docFundId: string) => void
) => {
  const res = await fetch(`${BACKEND_ADDR}/grants/ecosystem-projects`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(project),
    credentials: "include",
  });

  const projectId = (await res.json()).projectId;

  if (projectId) {
    callback(projectId);
  }
};

export const getProjectById = async (projectId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-projects/${projectId}`,
    {
      credentials: "include",
    }
  );

  if (res.ok) {
    return (await res.json()) as Project;
  } else if (res.status === 404) {
    throw new Error("Project not found");
  } else {
    throw new Error("Error fetching project");
  }
};

export const getDocFundById = async (docFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds/${docFundId}`,
    {
      credentials: "include",
    }
  );

  if (res.ok) {
    return await res.json();
  } else if (res.status === 404) {
    throw new Error("DocFund not found");
  } else {
    throw new Error("Error fetching DocFund");
  }
};

export const createDocFund = async (
  docFund: EcoFund,
  callback: (docFundId: string) => void
) => {
  const res = await fetch(`${BACKEND_ADDR}/grants/ecosystem-doc-funds`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(docFund),
    credentials: "include",
  });

  const docFundId = (await res.json()).docFundId;

  if (docFundId) {
    callback(docFundId);
  }
};

export const addProjectToDocFund = async (
  docFundId: number,
  projectId: number,
  callback: () => void
) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds/showcase/${docFundId}/${projectId}`,
    {
      method: "POST",
      credentials: "include",
    }
  );

  if (res.ok) {
    callback();
  }
};

export const getDocFundProjects = async (docFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds/projects/${docFundId}`,
    {
      credentials: "include",
    }
  );

  return await res.json();
};

export const allocateFunds = async (
  docFundId: string,
  allocations: Allocation[],
  callback: () => void
) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds/allocate/${docFundId}`,
    {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(allocations),
      credentials: "include",
    }
  );

  if (res.ok) {
    callback();
  }
};

export const getAllocators = async (docFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-doc-funds/allocators/${docFundId}`,
    {
      credentials: "include",
    }
  );

  return await res.json();
};
