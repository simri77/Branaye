import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import { Express } from 'express';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Branaye API',
      version: '1.0.0',
      description: 'API for Branaye Notes App',
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        Note: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'cuid' },
            title: { type: 'string', maxLength: 200 },
            content: { type: 'string', maxLength: 10000 },
            category: { type: 'string', enum: ['Personal', 'Work', 'Study', 'Ideas'] },
            color: { type: 'string', pattern: '^#[0-9A-Fa-f]{6}$' },
            isPinned: { type: 'boolean' },
            isFavorite: { type: 'boolean' },
            isArchived: { type: 'boolean' },
            tags: { type: 'array', items: { type: 'string' } },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
        },
        Tag: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'cuid' },
            name: { type: 'string', maxLength: 50 },
            color: { type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', nullable: true },
            noteCount: { type: 'integer' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
        },
        PaginatedNotes: {
          type: 'object',
          properties: {
            data: { type: 'array', items: { $ref: '#/components/schemas/Note' } },
            meta: {
              type: 'object',
              properties: {
                page: { type: 'integer' },
                limit: { type: 'integer' },
                total: { type: 'integer' },
                totalPages: { type: 'integer' },
              },
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            details: { type: 'object' },
          },
        },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ['./src/routes/*.ts'],
};

const swaggerSpec = swaggerJsdoc(options);

export function setupSwagger(app: Express) {
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  app.get('/api/docs.json', (_req, res) => {
    res.json(swaggerSpec);
  });
}