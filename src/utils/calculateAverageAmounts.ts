function calculateAverageAmounts(
  voters: { projectId: string; amount: string }[][],
  trackedProjectIds: string[]
) {
  const projectSums: { [projectId: string]: number } = {}; // To store the sum of amounts for each project
  const projectVotes: { [projectId: string]: number } = {}; // To store the total votes for each project

  // Iterate through each voter's input
  for (const voter of voters) {
    const votedProjects: { [projectId: string]: boolean } = {}; // To keep track of which projects each voter has voted for

    for (const { projectId, amount } of voter) {
      // Convert the amount to a number
      const amountNum = parseFloat(amount);

      // Check if the projectId is in the list of trackedProjectIds
      if (trackedProjectIds.includes(projectId)) {
        // Initialize sums and votes for the tracked project if not already done
        projectSums[projectId] = (projectSums[projectId] || 0) + amountNum;
        votedProjects[projectId] = true; // Mark that this voter has voted for this project
      }
    }

    // Update the total votes for each project based on the voter's choices
    for (const projectId of Object.keys(votedProjects)) {
      projectVotes[projectId] = (projectVotes[projectId] || 0) + 1;
    }
  }

  // Calculate the average amounts for tracked projects
  const averageAmounts = trackedProjectIds.map((projectId: string) => ({
    projectId,
    amount: (projectSums[projectId] / voters.length).toFixed(2), // Rounding to 2 decimal places
  }));

  return averageAmounts;
}

export default calculateAverageAmounts;

// Sample input
// const voters: { projectId: string; amount: string }[][] = [
//   [
//     {
//       projectId: "3",
//       amount: "150",
//     },
//     {
//       projectId: "2",
//       amount: "150",
//     },
//     {
//       projectId: "4",
//       amount: "100",
//     },
//   ],

//   [
//     {
//       projectId: "3",
//       amount: "100",
//     },
//     {
//       projectId: "2",
//       amount: "200",
//     },
//     {
//       projectId: "4",
//       amount: "100",
//     },
//   ],

//   [
//     {
//       projectId: "3",
//       amount: "0",
//     },
//     {
//       projectId: "2",
//       amount: "300",
//     },
//   ],
// ];
// const trackedProjectIds: string[] = ["2", "3", "4"]; // List of project IDs to track

// const result = calculateAverageAmounts(voters, trackedProjectIds);

// console.log(result);
