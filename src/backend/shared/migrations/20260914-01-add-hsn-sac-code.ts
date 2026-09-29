import type { DatabaseAdapter } from '../types/DatabaseAdapter';
import { getTableColumns } from '../utils/dbHelper';
import { mapDatabaseError } from '../utils/errorFunctions';

export const up = async (db: DatabaseAdapter) => {
  try {
    const itemColumns = await getTableColumns(db, 'items');
    if (!itemColumns.some(column => column.name === 'hsn_sac_code')) {
      await db.run('ALTER TABLE items ADD COLUMN "hsn_sac_code" TEXT');
    }

    const snapshotColumns = await getTableColumns(db, 'invoice_item_snapshots');
    if (!snapshotColumns.some(column => column.name === 'hsn_sac_code')) {
      await db.run('ALTER TABLE invoice_item_snapshots ADD COLUMN "hsn_sac_code" TEXT');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};

export const down = async (db: DatabaseAdapter) => {
  try {
    const itemColumns = await getTableColumns(db, 'items');
    if (itemColumns.some(column => column.name === 'hsn_sac_code')) {
      await db.run('ALTER TABLE items DROP COLUMN "hsn_sac_code"');
    }

    const snapshotColumns = await getTableColumns(db, 'invoice_item_snapshots');
    if (snapshotColumns.some(column => column.name === 'hsn_sac_code')) {
      await db.run('ALTER TABLE invoice_item_snapshots DROP COLUMN "hsn_sac_code"');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};
