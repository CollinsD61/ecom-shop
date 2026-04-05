import axios from "axios";
import AuthHeader from "./AuthHeader";

const LEGACY_BASE_API_URL = process.env.REACT_APP_BASE_API_URL || "";
const PRODUCT_API_BASE_URL = process.env.REACT_APP_PRODUCT_API_URL || `${LEGACY_BASE_API_URL}product/`;

const http = axios.create({
    baseURL: PRODUCT_API_BASE_URL,
});

class ProductService {
    getAll() {
        return http.get("", { headers: AuthHeader() });
    }

    get(id) {
        return http.get(`${id}`, { headers: AuthHeader() });
    }

    create(data) {
        return http.post("", data, { headers: AuthHeader() });
    }

    update(id, data) {
        return http.put(`${id}`, data, { headers: AuthHeader() });
    }

    delete(id) {
        return http.delete(`${id}`, { headers: AuthHeader() });
    }

    deleteAll() {
        return http.delete("deleteAll", { headers: AuthHeader() });
    }
}

const productService = new ProductService();

export default productService;