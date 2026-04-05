import { after } from 'mocha';
import pool from '../src/config/database.js';

after(async function () {
  try {
    await pool.end();
  } catch (_error) {
  }
});
