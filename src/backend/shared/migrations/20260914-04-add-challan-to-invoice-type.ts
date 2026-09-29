import type { DatabaseAdapter } from '../types/DatabaseAdapter';
import { isTableExists } from '../utils/dbHelper';

export const up = async (db: DatabaseAdapter) => {
  // No-op: migration 02 now includes 'challan' in the CHECK constraint
  if (!(await isTableExists(db, 'invoices'))) return;
};

export const down = async (_db: DatabaseAdapter) => {
  // Not reversible
};
