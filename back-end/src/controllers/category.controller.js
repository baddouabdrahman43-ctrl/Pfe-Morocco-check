import { successResponse } from '../utils/response.utils.js';
import { listCategories } from '../services/category.service.js';

export const getCategories = async (req, res) => {
  const result = await listCategories(req.query);
  return successResponse(res, result);
};
