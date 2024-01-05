// Calculate the flow rate per second
export function calculateFlowRate(
  tokensToSend: number,
  streamingDurationInSeconds: number
) {
  const precision = 1000_000_000;
  const flowRate = (tokensToSend / streamingDurationInSeconds) * precision;
  return flowRate;
}

// // Example usage:
// const tokensToSend = 11000 * 1_000_000;
// const streamingDuration = 3600 * 24 * 7; // in seconds
// const flowPerSecond = calculateFlowRate(tokensToSend, streamingDuration);

// console.log(
//   `Precision Token Unit flow rate per second: ${(
//     flowPerSecond
//   ).toLocaleString()} tokens`
// );

// console.log(`Real Token Unit Flow rate per second: ${flowPerSecond / 1000_000_000} tokens`);

// console.log(`${flowPerSecond / 1_000_000} tokens`);
