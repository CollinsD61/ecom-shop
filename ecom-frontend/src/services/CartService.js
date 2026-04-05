import axios from "axios";
import AuthHeader from "./AuthHeader";

const LEGACY_BASE_API_URL = process.env.REACT_APP_BASE_API_URL || "";
const CART_API_BASE_URL = process.env.REACT_APP_CART_API_URL || `${LEGACY_BASE_API_URL}shopping-cart/`;

const http = axios.create({
    baseURL: CART_API_BASE_URL,
});

class CartService {
    getAll() {
        return http.get("", { headers: AuthHeader() });
    }

    getById(cartId) {
        return http.get(`${cartId}`, { headers: AuthHeader() });
    }

    getByName(name) {
        return http.get(`by-name/${name}`, { headers: AuthHeader() });
    }

    create(name) {
        return http.post(`?name=${name}`, null, { headers: AuthHeader() });
    }

    delete(cartId) {
        return http.delete(`${cartId}`, { headers: AuthHeader() });
    }

    deleteProduct(cartId, productId) {
        return http.delete(`${cartId}/products/${productId}`, { headers: AuthHeader() });
    }

    getTotalPrice(cartId){
        return http.get(`totalprice/${cartId}`, { headers: AuthHeader() });
    }

    deleteAll() {
        return http.delete("deleteAll", { headers: AuthHeader() });
    }

    addProducts(cartId, data) {
        return http.post(`${cartId}`, data, { headers: AuthHeader() });
    }
}

const cartService = new CartService();

export default cartService;