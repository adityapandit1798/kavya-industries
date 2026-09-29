import type { DatabaseAdapter } from '../types/DatabaseAdapter';
import { getTableColumns } from '../utils/dbHelper';
import { mapDatabaseError } from '../utils/errorFunctions';

export const up = async (db: DatabaseAdapter) => {
  try {
    const invoiceColumns = await getTableColumns(db, 'invoices');
    if (!invoiceColumns.some(column => column.name === 'cgstRate')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "cgstRate" REAL DEFAULT 0');
    }
    if (!invoiceColumns.some(column => column.name === 'sgstRate')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "sgstRate" REAL DEFAULT 0');
    }
    if (!invoiceColumns.some(column => column.name === 'cgstAmount')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "cgstAmount" TEXT DEFAULT \'0\'');
    }
    if (!invoiceColumns.some(column => column.name === 'sgstAmount')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "sgstAmount" TEXT DEFAULT \'0\'');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};

export const down = async (db: DatabaseAdapter) => {
  try {
    const invoiceColumns = await getTableColumns(db, 'invoices');
    if (invoiceColumns.some(column => column.name === 'cgstRate')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "cgstRate"');
    }
    if (invoiceColumns.some(column => column.name === 'sgstRate')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "sgstRate"');
    }
    if (invoiceColumns.some(column => column.name === 'cgstAmount')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "cgstAmount"');
    }
    if (invoiceColumns.some(column => column.name === 'sgstAmount')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "sgstAmount"');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};
