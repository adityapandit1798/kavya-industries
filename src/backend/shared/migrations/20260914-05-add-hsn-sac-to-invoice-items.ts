import type { DatabaseAdapter } from '../types/DatabaseAdapter';
import { getTableColumns } from '../utils/dbHelper';
import { mapDatabaseError } from '../utils/errorFunctions';

export const up = async (db: DatabaseAdapter) => {
  try {
    const cols = await getTableColumns(db, 'invoice_items');
    if (!cols.some(c => c.name === 'hsn_sac_code')) {
      await db.run('ALTER TABLE invoice_items ADD COLUMN "hsn_sac_code" TEXT');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};

export const down = async (db: DatabaseAdapter) => {
  // Not reversible
};
