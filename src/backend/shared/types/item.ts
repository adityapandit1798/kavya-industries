export interface Item {
  id?: number;
  name: string;
  unitId?: number;
  amount?: string;
  categoryId?: number;
  categoryName?: string;
  unitName?: string;
  description?: string;
  hsn_sac_code?: string;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
  invoiceCount: number;
  quotesCount: number;
}
