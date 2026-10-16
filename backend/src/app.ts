import express from 'express';
import healthRoute from './routes/health.route';
import notesRoute from './routes/notes.route';
import tagsRoute from './routes/tags.route';
import authRoute from './routes/auth.route';
import { setupSwagger } from './config/swagger';
import { errorHandler } from './middleware/error';
import { cors } from './middleware/cors';

const app = express();

app.use(cors);
app.use(express.json());

app.use('/api', healthRoute);
app.use('/api/auth', authRoute);
app.use('/api/notes', notesRoute);
app.use('/api/tags', tagsRoute);

setupSwagger(app);

app.get('/', (_req, res) => {
  res.send('Hello World!');
});

app.use(errorHandler);

export default app;