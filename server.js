const express = require('express');
const bodyParser = require('body-parser');
const { exec } = require('child_process');

const app = express();
app.use(bodyParser.json());

app.post('/bind', (req, res) => {
  const { switchNode, lightNode, endpoint = 1, cluster = 6 } = req.body;
  const cmd = `chip-tool binding write binding '[{"node":${lightNode},"endpoint":1,"cluster":${cluster}}]' ${switchNode} ${endpoint}`;
  console.log(`Running: ${cmd}`);
  exec(cmd, (error, stdout, stderr) => {
    if (error) return res.status(500).json({ status: 'error', stderr });
    res.json({ status: 'ok', output: stdout });
  });
});

app.post('/toggle', (req, res) => {
  const { nodeId, endpoint = 1 } = req.body;
  const cmd = `chip-tool onoff toggle ${nodeId} ${endpoint}`;
  console.log(`Running: ${cmd}`);
  exec(cmd, (error, stdout, stderr) => {
    if (error) return res.status(500).json({ status: 'error', stderr });
    res.json({ status: 'ok', output: stdout });
  });
});

app.listen(5000, () => {
  console.log('Matter API server listening on port 5000');
});