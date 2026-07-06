import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function runMigration(filePath: string) {
  const client = await pool.connect();
  try {
    const sql = fs.readFileSync(filePath, 'utf-8');
    await client.query(sql);
    console.log(`✓ Migration applied: ${path.basename(filePath)}`);
  } catch (error) {
    console.error(`✗ Migration failed: ${path.basename(filePath)}`, error);
    throw error;
  } finally {
    client.release();
  }
}

async function migrate() {
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs.readdirSync(migrationsDir).sort();

  console.log('Running migrations...');
  
  for (const file of files) {
    if (file.endsWith('.sql')) {
      await runMigration(path.join(migrationsDir, file));
    }
  }

  console.log('✓ All migrations completed successfully');
  process.exit(0);
}

migrate().catch((error) => {
  console.error('Migration error:', error);
  process.exit(1);
});
