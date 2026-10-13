import { Router } from 'express';
import { prisma } from '../db';

const router = Router();

router.get('/health', async (_req, res) =>{
    await prisma.$queryRaw `SELECT 1`;
    res.json({status: 'ok', database: 'connected'})
});

export default router;