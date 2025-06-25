import { Context } from "@hono/hono";

export function testPageHandler(c: Context): Response {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Funnel API Test</title>
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
      max-width: 800px;
      margin: 0 auto;
    }
    
    h1 {
      font-size: 2.5rem;
      margin-bottom: 1rem;
      color: #2d3748;
    }
    
    .card {
      background: white;
      padding: 2rem;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      margin-bottom: 2rem;
    }
    
    .card h2 {
      font-size: 1.5rem;
      margin-bottom: 1rem;
      color: #2d3748;
    }
    
    .controls {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
      flex-wrap: wrap;
    }
    
    .btn {
      padding: 0.75rem 1.5rem;
      border: none;
      border-radius: 8px;
      font-size: 1rem;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
    }
    
    .btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
    
    .btn-primary {
      background: #4299e1;
      color: white;
    }
    
    .btn-primary:hover:not(:disabled) {
      background: #3182ce;
    }
    
    .btn-danger {
      background: #e53e3e;
      color: white;
    }
    
    .btn-danger:hover:not(:disabled) {
      background: #c53030;
    }
    
    .btn-success {
      background: #48bb78;
      color: white;
    }
    
    .btn-success:hover:not(:disabled) {
      background: #38a169;
    }
    
    .status {
      padding: 0.5rem 1rem;
      border-radius: 8px;
      margin-bottom: 1rem;
      font-weight: 500;
    }
    
    .status-info {
      background: #bee3f8;
      color: #2c5282;
    }
    
    .status-success {
      background: #c6f6d5;
      color: #2f855a;
    }
    
    .status-error {
      background: #fed7d7;
      color: #c53030;
    }
    
    .transcript-box {
      background: #f7fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 1rem;
      margin-top: 1rem;
      min-height: 100px;
      max-height: 300px;
      overflow-y: auto;
    }
    
    .transcript-segment {
      padding: 0.25rem 0;
      border-bottom: 1px solid #e2e8f0;
    }
    
    .transcript-segment:last-child {
      border-bottom: none;
    }
    
    .transcript-segment.final {
      color: #2d3748;
      font-weight: 500;
    }
    
    .transcript-segment.interim {
      color: #718096;
      font-style: italic;
    }
    
    .result-box {
      background: #f7fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 1rem;
      margin-top: 1rem;
      white-space: pre-wrap;
      font-family: 'Monaco', 'Courier New', monospace;
      font-size: 0.875rem;
      max-height: 400px;
      overflow-y: auto;
    }
    
    .recording-id {
      font-family: 'Monaco', 'Courier New', monospace;
      background: #edf2f7;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
      font-size: 0.875rem;
    }
    
    .visualizer {
      width: 100%;
      height: 100px;
      background: #1a202c;
      border-radius: 8px;
      margin: 1rem 0;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
      overflow: hidden;
    }
    
    .visualizer canvas {
      width: 100%;
      height: 100%;
    }
    
    .info-text {
      color: #718096;
      font-size: 0.875rem;
      margin-top: 0.5rem;
    }
    
    /* Card styles for results */
    .cards-container {
      display: none;
      margin-top: 2rem;
    }
    
    .card-tabs {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
      border-bottom: 2px solid #e2e8f0;
    }
    
    .card-tab {
      padding: 0.75rem 1.5rem;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      font-size: 1rem;
      font-weight: 500;
      color: #718096;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .card-tab:hover {
      color: #2d3748;
    }
    
    .card-tab.active {
      color: #4299e1;
      border-bottom-color: #4299e1;
    }
    
    .card-content {
      display: none;
      animation: fadeIn 0.3s ease-in-out;
    }
    
    .card-content.active {
      display: block;
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    .bullet-list {
      list-style: none;
      padding: 0;
    }
    
    .bullet-list li {
      padding: 0.75rem 0;
      padding-left: 1.5rem;
      position: relative;
      border-bottom: 1px solid #e2e8f0;
    }
    
    .bullet-list li:last-child {
      border-bottom: none;
    }
    
    .bullet-list li:before {
      content: "•";
      position: absolute;
      left: 0;
      color: #4299e1;
      font-weight: bold;
      font-size: 1.25rem;
    }
    
    .diagram-container {
      background: #1a202c;
      color: #48bb78;
      padding: 2rem;
      border-radius: 8px;
      font-family: 'Monaco', 'Courier New', monospace;
      white-space: pre;
      overflow-x: auto;
      line-height: 1.4;
    }
    
    .diagram-header {
      margin-bottom: 1rem;
    }
    
    .diagram-title {
      font-size: 1.25rem;
      font-weight: bold;
      color: #68d391;
      margin-bottom: 0.5rem;
    }
    
    .diagram-description {
      color: #a0aec0;
      font-size: 0.875rem;
    }
    
    .full-transcript {
      background: #f7fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 1.5rem;
      line-height: 1.8;
      max-height: 400px;
      overflow-y: auto;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Funnel API Test</h1>
    
    <div class="card">
      <h2>Stream Recording Test</h2>
      <p class="info-text">Test the new streaming API that sends audio chunks in real-time</p>
      
      <div class="controls">
        <button id="startBtn" class="btn btn-primary">
          <span>🎤</span> Start Recording
        </button>
        <button id="stopBtn" class="btn btn-danger" disabled>
          <span>⏹</span> Stop Recording
        </button>
        <button id="finalizeBtn" class="btn btn-success" disabled>
          <span>✅</span> Finalize & Process
        </button>
      </div>
      
      <div id="status" class="status status-info">Ready to record</div>
      
      <div>Recording ID: <span id="recordingId" class="recording-id">—</span></div>
      
      <div class="visualizer">
        <canvas id="visualizer"></canvas>
      </div>
      
      <h3>Live Transcript</h3>
      <div id="transcript" class="transcript-box">
        <em>Transcript will appear here...</em>
      </div>
      
      <div id="cards-container" class="cards-container">
        <h3>Processing Results</h3>
        <div class="card-tabs">
          <button class="card-tab active" onclick="showCard('summary')">Bullet Summary</button>
          <button class="card-tab" onclick="showCard('diagram')">Visual Diagram</button>
          <button class="card-tab" onclick="showCard('transcript')">Full Transcript</button>
        </div>
        
        <div id="card-summary" class="card-content active">
          <ul id="bullet-list" class="bullet-list"></ul>
        </div>
        
        <div id="card-diagram" class="card-content">
          <div class="diagram-container">
            <div class="diagram-header">
              <div id="diagram-title" class="diagram-title"></div>
              <div id="diagram-description" class="diagram-description"></div>
            </div>
            <div id="diagram-content"></div>
          </div>
        </div>
        
        <div id="card-transcript" class="card-content">
          <div id="full-transcript" class="full-transcript"></div>
        </div>
      </div>
      
      <div id="result" class="result-box" style="display: none;">
        <em>Raw JSON result for debugging</em>
      </div>
    </div>
    
    <div class="card">
      <h2>Quick Links</h2>
      <div class="controls">
        <a href="/api/admin" class="btn btn-primary">Admin Dashboard</a>
        <a href="/" class="btn btn-primary">API Health Check</a>
      </div>
    </div>
  </div>
  
  <script>
    let mediaRecorder;
    let audioContext;
    let analyser;
    let microphone;
    let websocket;
    let recordingId;
    let animationId;
    
    const startBtn = document.getElementById('startBtn');
    const stopBtn = document.getElementById('stopBtn');
    const finalizeBtn = document.getElementById('finalizeBtn');
    const statusDiv = document.getElementById('status');
    const transcriptDiv = document.getElementById('transcript');
    const resultDiv = document.getElementById('result');
    const recordingIdSpan = document.getElementById('recordingId');
    const canvas = document.getElementById('visualizer');
    const canvasCtx = canvas.getContext('2d');
    
    // Set canvas size
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;
    
    startBtn.addEventListener('click', startRecording);
    stopBtn.addEventListener('click', stopRecording);
    finalizeBtn.addEventListener('click', finalizeRecording);
    
    async function startRecording() {
      try {
        // Generate recording ID
        recordingId = crypto.randomUUID();
        recordingIdSpan.textContent = recordingId;
        
        // Request microphone access
        const stream = await navigator.mediaDevices.getUserMedia({ 
          audio: {
            channelCount: 1,
            sampleRate: 16000,
            echoCancellation: true,
            noiseSuppression: true,
          } 
        });
        
        // Setup audio context for visualization
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        analyser = audioContext.createAnalyser();
        microphone = audioContext.createMediaStreamSource(stream);
        microphone.connect(analyser);
        analyser.fftSize = 256;
        
        // Start visualization
        visualize();
        
        // Setup WebSocket connection
        const wsUrl = \`ws://\${window.location.host}/api/recordings/\${recordingId}/stream\`;
        websocket = new WebSocket(wsUrl);
        
        websocket.onopen = () => {
          console.log('WebSocket connected');
          updateStatus('Connected to server, initializing...', 'info');
        };
        
        websocket.onmessage = (event) => {
          const data = JSON.parse(event.data);
          
          if (data.type === 'ready') {
            updateStatus('Recording and transcribing...', 'success');
          } else if (data.type === 'transcript') {
            updateTranscript(data.segment, data.fullTranscript);
          } else if (data.type === 'error') {
            updateStatus(\`Error: \${data.message}\`, 'error');
          }
        };
        
        websocket.onerror = (error) => {
          console.error('WebSocket error:', error);
          updateStatus('Connection error', 'error');
        };
        
        websocket.onclose = () => {
          console.log('WebSocket closed');
          if (mediaRecorder && mediaRecorder.state === 'recording') {
            stopRecording();
          }
        };
        
        // Wait for WebSocket to connect
        await new Promise((resolve) => {
          const checkConnection = setInterval(() => {
            if (websocket.readyState === WebSocket.OPEN) {
              clearInterval(checkConnection);
              resolve();
            }
          }, 100);
        });
        
        // Setup MediaRecorder
        const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
          ? 'audio/webm;codecs=opus'
          : 'audio/webm';
          
        mediaRecorder = new MediaRecorder(stream, {
          mimeType,
          audioBitsPerSecond: 128000
        });
        
        mediaRecorder.ondataavailable = (event) => {
          if (event.data.size > 0 && websocket.readyState === WebSocket.OPEN) {
            websocket.send(event.data);
          }
        };
        
        // Start recording with 100ms chunks
        mediaRecorder.start(100);
        
        // Update UI
        startBtn.disabled = true;
        stopBtn.disabled = false;
        finalizeBtn.disabled = true;
        transcriptDiv.innerHTML = '<em>Listening...</em>';
        resultDiv.innerHTML = '<em>Results will appear after finalization...</em>';
        
      } catch (error) {
        console.error('Error starting recording:', error);
        updateStatus(\`Error: \${error.message}\`, 'error');
      }
    }
    
    function stopRecording() {
      if (mediaRecorder && mediaRecorder.state !== 'inactive') {
        mediaRecorder.stop();
        mediaRecorder.stream.getTracks().forEach(track => track.stop());
      }
      
      if (websocket) {
        websocket.close();
      }
      
      if (animationId) {
        cancelAnimationFrame(animationId);
      }
      
      if (audioContext) {
        audioContext.close();
      }
      
      // Update UI
      startBtn.disabled = false;
      stopBtn.disabled = true;
      finalizeBtn.disabled = false;
      updateStatus('Recording stopped. Click "Finalize & Process" to generate summary.', 'info');
      
      // Clear visualizer
      canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
    }
    
    async function finalizeRecording() {
      try {
        updateStatus('Processing recording...', 'info');
        finalizeBtn.disabled = true;
        
        const response = await fetch(\`/api/recordings/\${recordingId}/done\`, {
          method: 'POST',
        });
        
        if (!response.ok) {
          throw new Error(\`Server error: \${response.status}\`);
        }
        
        const result = await response.json();
        
        updateStatus('Processing complete!', 'success');
        displayResult(result);
        
        // Reset for next recording
        recordingId = null;
        recordingIdSpan.textContent = '—';
        
      } catch (error) {
        console.error('Error finalizing recording:', error);
        updateStatus(\`Error: \${error.message}\`, 'error');
        finalizeBtn.disabled = false;
      }
    }
    
    function updateStatus(message, type) {
      statusDiv.textContent = message;
      statusDiv.className = \`status status-\${type}\`;
    }
    
    function updateTranscript(segment, fullTranscript) {
      // Clear initial message
      if (transcriptDiv.innerHTML === '<em>Listening...</em>') {
        transcriptDiv.innerHTML = '';
      }
      
      // Add new segment
      const segmentDiv = document.createElement('div');
      segmentDiv.className = \`transcript-segment \${segment.isFinal ? 'final' : 'interim'}\`;
      segmentDiv.textContent = segment.text;
      transcriptDiv.appendChild(segmentDiv);
      
      // Auto-scroll to bottom
      transcriptDiv.scrollTop = transcriptDiv.scrollHeight;
    }
    
    function displayResult(result) {
      // Hide the old result box and show cards
      document.getElementById('result').style.display = 'none';
      document.getElementById('cards-container').style.display = 'block';
      
      // Populate bullet summary
      const bulletList = document.getElementById('bullet-list');
      bulletList.innerHTML = '';
      if (result.bulletSummary && result.bulletSummary.length > 0) {
        result.bulletSummary.forEach(bullet => {
          const li = document.createElement('li');
          li.textContent = bullet;
          bulletList.appendChild(li);
        });
      } else {
        bulletList.innerHTML = '<li>No summary available</li>';
      }
      
      // Populate diagram
      if (result.diagram) {
        document.getElementById('diagram-title').textContent = result.diagram.title || 'Diagram';
        document.getElementById('diagram-description').textContent = result.diagram.description || '';
        document.getElementById('diagram-content').textContent = result.diagram.content || '[No diagram]';
      }
      
      // Populate full transcript
      const transcriptDiv = document.getElementById('full-transcript');
      transcriptDiv.textContent = result.transcript || 'No transcript available';
      
      // Store result for debugging
      window.lastResult = result;
      console.log('Processing result:', result);
    }
    
    window.showCard = function(cardType) {
      // Update tab styles
      document.querySelectorAll('.card-tab').forEach(tab => {
        tab.classList.remove('active');
      });
      event.target.classList.add('active');
      
      // Update card content
      document.querySelectorAll('.card-content').forEach(content => {
        content.classList.remove('active');
      });
      document.getElementById(\`card-\${cardType}\`).classList.add('active');
    };
    
    function visualize() {
      const bufferLength = analyser.frequencyBinCount;
      const dataArray = new Uint8Array(bufferLength);
      
      function draw() {
        animationId = requestAnimationFrame(draw);
        
        analyser.getByteFrequencyData(dataArray);
        
        canvasCtx.fillStyle = '#1a202c';
        canvasCtx.fillRect(0, 0, canvas.width, canvas.height);
        
        const barWidth = (canvas.width / bufferLength) * 2.5;
        let barHeight;
        let x = 0;
        
        for (let i = 0; i < bufferLength; i++) {
          barHeight = (dataArray[i] / 255) * canvas.height * 0.8;
          
          const hue = (i / bufferLength) * 200 + 160; // Blue to green gradient
          canvasCtx.fillStyle = \`hsl(\${hue}, 70%, 50%)\`;
          canvasCtx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
          
          x += barWidth + 1;
        }
      }
      
      draw();
    }
  </script>
</body>
</html>
  `;

  return c.html(html);
}
