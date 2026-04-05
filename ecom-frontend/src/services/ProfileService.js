import axios from "axios";
import AuthHeader from "./AuthHeader";

const LEGACY_BASE_API_URL = process.env.REACT_APP_BASE_API_URL || "";
const USER_API_BASE_URL = process.env.REACT_APP_USER_API_URL || `${LEGACY_BASE_API_URL}user/`;

const http = axios.create({
    baseURL: USER_API_BASE_URL,
});

class ProfileService {
    update(userId, data) {
        return http.put(`update/${userId}`, data, { headers: AuthHeader() })
    }

    delete(userId) {
        return http.delete(`delete/${userId}`, { headers: AuthHeader() });
    }
}

const profileService = new ProfileService();

export default profileService;