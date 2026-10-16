import { describe, it, expect } from 'vitest';
import express from 'express';
import request from 'supertest';
import { cors } from '../cors';

function buildApp(): express.Express {
  const app = express();
  app.use(cors);
  app.get('/ping', (_req, res) => {
    res.json({ pong: true });
  });
  return app;
}

describe('cors middleware', () => {
  it('answers a preflight with 204 and the allowed headers', async () => {
    const response = await request(buildApp())
      .options('/ping')
      .set('Origin', 'http://localhost:8095')
      .set('Access-Control-Request-Method', 'POST');

    expect(response.status).toBe(204);
    expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8095');
    expect(response.headers['access-control-allow-methods']).toContain('PATCH');
    expect(response.headers['access-control-allow-headers']).toContain('Authorization');
  });

  it('reflects the origin on a normal request', async () => {
    const response = await request(buildApp())
      .get('/ping')
      .set('Origin', 'http://localhost:8095');

    expect(response.status).toBe(200);
    expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8095');
  });
});
