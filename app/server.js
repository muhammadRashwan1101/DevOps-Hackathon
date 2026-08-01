const express = require('express');

const app = express();
const PORT = 3000;
const APP_NAME = process.env.APP_NAME || 'CloudPipe';

app.get('/', (req, res) => {
  res.status(200).send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>${APP_NAME}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #0f172a;
          color: #f8fafc;
          display: flex;
          align-items: center;
          justify-content: center;
          height: 100vh;
          margin: 0;
        }
        .card {
          background-color: #1e293b;
          padding: 2rem 3rem;
          border-radius: 12px;
          text-align: center;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
        }
        h1 {
          color: #38bdf8;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Welcome to ${APP_NAME}</h1>
        <p>This application is running inside a Kubernetes pod on Minikube.</p>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`${APP_NAME} listening on port ${PORT}`);
});