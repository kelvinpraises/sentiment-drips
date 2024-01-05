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

export const getEcoFunds = async (userId?: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds?userId=${userId}`,
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
  callback: (ecoFundId: string) => void
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

export const getEcoFundById = async (ecoFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds/${ecoFundId}`,
    {
      credentials: "include",
    }
  );

  if (res.ok) {
    return await res.json();
  } else if (res.status === 404) {
    throw new Error("ecoFund not found");
  } else {
    throw new Error("Error fetching ecoFund");
  }
};

export const createEcoFund = async (
  ecoFund: EcoFund,
  callback: (ecoFundId: string) => void
) => {
  const res = await fetch(`${BACKEND_ADDR}/grants/ecosystem-eco-funds`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(ecoFund),
    credentials: "include",
  });

  const ecoFundId = (await res.json()).ecoFundId;

  if (ecoFundId) {
    callback(ecoFundId);
  }
};

export const addProjectToEcoFund = async (
  ecoFundId: number,
  projectId: number,
  callback: () => void
) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds/showcase/${ecoFundId}/${projectId}`,
    {
      method: "POST",
      credentials: "include",
    }
  );

  if (res.ok) {
    callback();
  }
};

export const getEcoFundProjects = async (ecoFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds/projects/${ecoFundId}`,
    {
      credentials: "include",
    }
  );

  return await res.json();
};

export const allocateFunds = async (
  ecoFundId: string,
  allocations: Allocation[],
  callback: () => void
) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds/allocate/${ecoFundId}`,
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

export const getAllocators = async (ecoFundId: string) => {
  const res = await fetch(
    `${BACKEND_ADDR}/grants/ecosystem-eco-funds/allocators/${ecoFundId}`,
    {
      credentials: "include",
    }
  );

  return await res.json();
};
