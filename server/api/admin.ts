import { Context } from "@hono/hono";
import { RecordingData } from "../lib/deepgram.ts";
import { ProcessedRecording } from "../lib/ai-processing.ts";

const kv = await Deno.openKv();

export async function adminHandler(c: Context): Promise<Response> {
  const recordings: RecordingData[] = [];
  const processed: ProcessedRecording[] = [];

  // Get all recordings
  const recordingIter = kv.list<RecordingData>({ prefix: ["recordings"] });
  for await (const entry of recordingIter) {
    recordings.push(entry.value);
  }

  // Get all processed recordings
  const processedIter = kv.list<ProcessedRecording>({ prefix: ["processed"] });
  for await (const entry of processedIter) {
    processed.push(entry.value);
  }

  // Sort by start time (newest first)
  recordings.sort((a, b) =>
    new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
  );

  const html = generateAdminHTML(recordings, processed);
  return c.html(html);
}

function generateAdminHTML(
  recordings: RecordingData[],
  processed: ProcessedRecording[],
): string {
  const processedMap = new Map(processed.map((p) => [p.id, p]));

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Funnel Admin</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f7fa;
      color: #1a202c;
      line-height: 1.6;
      padding: 20px;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    
    h1 {
      font-size: 2.5rem;
      margin-bottom: 2rem;
      color: #2d3748;
    }
    
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 3rem;
    }
    
    .stat-card {
      background: white;
      padding: 1.5rem;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }
    
    .stat-label {
      font-size: 0.875rem;
      color: #718096;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    
    .stat-value {
      font-size: 2rem;
      font-weight: 600;
      color: #2d3748;
      margin-top: 0.5rem;
    }
    
    .recordings-table {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
    }
    
    th {
      background: #f7fafc;
      font-weight: 600;
      text-align: left;
      padding: 1rem;
      font-size: 0.875rem;
      color: #4a5568;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    
    td {
      padding: 1rem;
      border-bottom: 1px solid #e2e8f0;
    }
    
    tr:last-child td {
      border-bottom: none;
    }
    
    tr:hover {
      background: #f7fafc;
    }
    
    .status {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
    }
    
    .status-recording {
      background: #fed7d7;
      color: #c53030;
    }
    
    .status-processing {
      background: #feebc8;
      color: #c05621;
    }
    
    .status-completed {
      background: #c6f6d5;
      color: #2f855a;
    }
    
    .status-error {
      background: #fed7d7;
      color: #c53030;
    }
    
    .transcript-preview {
      max-width: 300px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      color: #718096;
      font-size: 0.875rem;
    }
    
    .actions {
      display: flex;
      gap: 0.5rem;
    }
    
    .btn {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 6px;
      font-size: 0.875rem;
      font-weight: 500;
      cursor: pointer;
      text-decoration: none;
      display: inline-block;
      transition: all 0.2s;
    }
    
    .btn-primary {
      background: #4299e1;
      color: white;
    }
    
    .btn-primary:hover {
      background: #3182ce;
    }
    
    .btn-secondary {
      background: #e2e8f0;
      color: #4a5568;
    }
    
    .btn-secondary:hover {
      background: #cbd5e0;
    }
    
    .empty-state {
      text-align: center;
      padding: 4rem 2rem;
      color: #718096;
    }
    
    .empty-state h3 {
      font-size: 1.5rem;
      margin-bottom: 0.5rem;
      color: #4a5568;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Funnel Admin Dashboard</h1>
    
    <div class="stats">
      <div class="stat-card">
        <div class="stat-label">Total Recordings</div>
        <div class="stat-value">${recordings.length}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Completed</div>
        <div class="stat-value">${
    recordings.filter((r) => r.status === "completed").length
  }</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Processing</div>
        <div class="stat-value">${
    recordings.filter((r) => r.status === "processing").length
  }</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Active</div>
        <div class="stat-value">${
    recordings.filter((r) => r.status === "recording").length
  }</div>
      </div>
    </div>
    
    <div class="recordings-table">
      ${
    recordings.length === 0
      ? `
        <div class="empty-state">
          <h3>No recordings yet</h3>
          <p>Recordings will appear here once created</p>
        </div>
      `
      : `
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Status</th>
              <th>Start Time</th>
              <th>Duration</th>
              <th>Transcript</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            ${
        recordings.map((recording) => {
          const processedData = processedMap.get(recording.id);
          const duration = recording.duration
            ? formatDuration(recording.duration)
            : recording.endTime
            ? formatDuration(
              (new Date(recording.endTime).getTime() -
                new Date(recording.startTime).getTime()) / 1000,
            )
            : "Recording...";

          return `
                <tr>
                  <td><code>${recording.id}</code></td>
                  <td>
                    <span class="status status-${recording.status}">
                      ${recording.status}
                    </span>
                  </td>
                  <td>${new Date(recording.startTime).toLocaleString()}</td>
                  <td>${duration}</td>
                  <td>
                    <div class="transcript-preview">
                      ${
            recording.transcript || processedData?.transcript || "—"
          }
                    </div>
                  </td>
                  <td>
                    <div class="actions">
                      ${
            recording.status === "completed" && processedData
              ? `
                        <button class="btn btn-primary" onclick="viewDetails('${recording.id}')">
                          View
                        </button>
                      `
              : ""
          }
                      <a href="/api/test" class="btn btn-secondary">Test API</a>
                    </div>
                  </td>
                </tr>
              `;
        }).join("")
      }
          </tbody>
        </table>
      `
  }
    </div>
  </div>
  
  <script>
    function viewDetails(recordingId) {
      // In a real app, this would navigate to a detail view
      alert('Recording details for: ' + recordingId);
    }
    
    // Auto-refresh every 5 seconds
    setTimeout(() => {
      window.location.reload();
    }, 5000);
  </script>
</body>
</html>
  `;
}

function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}
