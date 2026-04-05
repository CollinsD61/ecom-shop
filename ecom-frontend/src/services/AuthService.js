import axios from "axios";

const LEGACY_BASE_API_URL = process.env.REACT_APP_BASE_API_URL || "";
const USER_API_BASE_URL = process.env.REACT_APP_USER_API_URL || `${LEGACY_BASE_API_URL}user/`;

const http = axios.create({
    baseURL: USER_API_BASE_URL,
});

class AuthService {
    login(username, password) {
        return http
            .post("signin", { username, password })
            .then((response) => {
                if (response.data.accessToken) {
                    localStorage.setItem("user", JSON.stringify(response.data));
                }

                return response.data;
            });
    }

    logout() {
        localStorage.removeItem("user");
    }

    register(username, email, password) {
        return http.post("signup", {
            username,
            email,
            password,
        });
    }
}

const authService = new AuthService();

export default authService;