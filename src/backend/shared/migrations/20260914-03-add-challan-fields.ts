import type { DatabaseAdapter } from '../types/DatabaseAdapter';
import { getTableColumns } from '../utils/dbHelper';
import { mapDatabaseError } from '../utils/errorFunctions';

export const up = async (db: DatabaseAdapter) => {
  try {
    const invoiceColumns = await getTableColumns(db, 'invoices');
    if (!invoiceColumns.some(column => column.name === 'vehicleNumber')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "vehicleNumber" TEXT DEFAULT \'\'');
    }
    if (!invoiceColumns.some(column => column.name === 'transporterName')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "transporterName" TEXT DEFAULT \'\'');
    }
    if (!invoiceColumns.some(column => column.name === 'receiverName')) {
      await db.run('ALTER TABLE invoices ADD COLUMN "receiverName" TEXT DEFAULT \'\'');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};

export const down = async (db: DatabaseAdapter) => {
  try {
    const invoiceColumns = await getTableColumns(db, 'invoices');
    if (invoiceColumns.some(column => column.name === 'vehicleNumber')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "vehicleNumber"');
    }
    if (invoiceColumns.some(column => column.name === 'transporterName')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "transporterName"');
    }
    if (invoiceColumns.some(column => column.name === 'receiverName')) {
      await db.run('ALTER TABLE invoices DROP COLUMN "receiverName"');
    }
  } catch (error) {
    return { success: false, ...mapDatabaseError(error, db.type) };
  }
};
