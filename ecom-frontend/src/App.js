import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { Container, Navbar, Nav, Form, FormControl, Button } from "react-bootstrap";
import { Search, ShoppingCart, Notifications, Help, Language } from "@mui/icons-material";
import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";

import LoginComponent from "./components/LoginComponent";
import RegisterComponent from "./components/RegisterComponent";
import HomeComponent from "./components/HomeComponent";
import ProfileComponent from "./components/ProfileComponent";
import ProductsListComponent from "./components/ProductsListComponent";
import CartComponent from "./components/CartComponent";
import AddProductComponent from "./components/AddProductComponent";
import ProductEditComponent from "./components/ProductEditComponent";

import { logout } from "./actions/auth";
import { connect } from "react-redux";
import { clearMessage } from "./actions/message";
import { history } from './helpers/history';

import AuthVerify from "./common/AuthVerify";
import EventBus from "./common/EventBus";
import { Login, Logout, Person, PersonAdd } from "@mui/icons-material";
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import ProfileEditComponent from "./components/ProfileEditComponent";

class App extends Component {
  constructor(props) {
    super(props);
    this.logOut = this.logOut.bind(this);

    this.state = {
      currentUser: undefined,
    };

    history.listen((location) => {
      props.dispatch(clearMessage());
    });
  }

  componentDidMount() {
    const user = this.props.user;

    if (user) {
      this.setState({
        currentUser: user
      });
    }

    EventBus.on("logout", () => {
      this.logOut();
    });
  }

  componentWillUnmount() {
    EventBus.remove("logout");
  }

  logOut() {
    this.props.dispatch(logout());
    this.setState({
      currentUser: undefined,
    });
  }

  render() {
    const { currentUser } = this.state;

    // Refined Minimalist Aesthetic
    const appStyle = `
      @import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500&family=Syne:wght@600;700;800&display=swap');
      
      body {
        margin: 0;
        font-family: 'DM Sans', sans-serif;
        background-color: #f8f9fa;
        color: #111;
      }
      .header-container {
        top: 0;
        position: sticky;
        z-index: 1000;
        box-shadow: 0 4px 30px rgba(0, 0, 0, 0.05);
      }
      .header-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: #000;
        color: #f0f0f0;
        font-size: 12px;
        padding: 8px 40px;
        letter-spacing: 0.05em;
        text-transform: uppercase;
      }
      .header-top a {
        color: #b0b0b0;
        text-decoration: none;
        margin-left: 20px;
        transition: color 0.3s ease;
      }
      .header-top a:hover {
        color: #fff;
      }
      .navbar {
        background-color: #ffffff;
        padding: 20px 40px;
        border-bottom: 1px solid #eaeaea;
      }
      .navbar-brand img {
        filter: grayscale(100%) contrast(1.2);
        transition: transform 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
      }
      .navbar-brand:hover img {
        transform: scale(1.05);
      }
      .search-form {
        display: flex;
        width: 500px;
        border: 1px solid #ccc;
        border-radius: 30px;
        overflow: hidden;
        transition: border-color 0.3s ease;
      }
      .search-form:focus-within {
        border-color: #000;
      }
      .search-form input {
        flex: 1;
        border: none;
        padding: 12px 20px;
        font-family: 'DM Sans', sans-serif;
        font-size: 14px;
        outline: none;
      }
      .search-button {
        background-color: transparent;
        border: none;
        padding: 0 20px;
        color: #000;
        transition: background-color 0.3s ease;
      }
      .search-button:hover {
        background-color: #f0f0f0;
      }
      .search-button svg {
        color: #000;
      }
      .nav-icons a {
        color: #000;
        margin-left: 25px;
        transition: transform 0.3s ease;
        display: inline-block;
      }
      .nav-icons a:hover {
        transform: translateY(-2px);
      }
      .auth-links {
        font-family: 'Syne', sans-serif;
        font-weight: 600;
        letter-spacing: 0.05em;
      }
      
      /* Global Card Styling for Login/Register */
      .cardLogin {
        background: #fff;
        padding: 40px;
        border-radius: 16px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.08);
        border: 1px solid #f0f0f0;
        max-width: 450px;
        margin: 60px auto;
        font-family: 'DM Sans', sans-serif;
      }
      .cardLogin label {
        font-family: 'Syne', sans-serif;
        font-weight: 700;
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        margin-bottom: 8px;
        display: block;
        color: #333;
      }
      .cardLogin .form-control {
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 12px 16px;
        font-size: 14px;
        transition: all 0.3s ease;
      }
      .cardLogin .form-control:focus {
        border-color: #000;
        box-shadow: 0 0 0 2px rgba(0,0,0,0.1);
        outline: none;
      }
      .cardLogin .btn-primary {
        background-color: #000;
        border: none;
        border-radius: 30px;
        padding: 12px 30px;
        font-family: 'Syne', sans-serif;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        font-weight: 700;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
      }
      .cardLogin .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        background-color: #222;
      }
      .profile-img-card {
        width: 80px;
        height: 80px;
        margin: 0 auto 30px;
        display: block;
        opacity: 0.8;
      }
    `;

    return (
      <>
        {/* Inject CSS */}
        <style>{appStyle}</style>
        <div class="header-container">
        {/* Header Top */}
        <div className="header-top">
          <div>
            <a href="https://devopsedu.vn/" target="_blank">Kênh bản quyền</a>
            <a href="https://devopsedu.vn/contact/" target="_blank">Trở thành người đóng góp</a>
            <a href="https://devopsedu.vn/blog/" target="_blank">Tài liệu tham khảo</a>
            <a href="https://m.me/139689492555066" target="_blank">Liên hệ</a>
          </div>
          <div>
            <a href="#"><Notifications /></a>
            <a href="#"><Help /></a>
            <a href="#"><Language /> Tiếng Việt</a>
            {currentUser ? (
              <>
                <Link to="/profile" className="auth-links">{currentUser.username}</Link>
                <a href="#" className="auth-links" onClick={this.logOut}>Đăng Xuất</a>
              </>
            ) : (
              <>
                <Link to="/register" className="auth-links">Đăng Ký</Link>
                <Link to="/login" className="auth-links">Đăng Nhập</Link>
              </>
            )}
          </div>
        </div>

        {/* Navbar */}
        <Navbar expand="lg" className="navbar" variant="light">
          <Container fluid>
            {/* Logo */}
            <Navbar.Brand as={Link} to="/">
              <img
                src="/Shop now-logo.png"
                alt="Logo"
                width="120"
                height="40"
              />
            </Navbar.Brand>

            {/* Thanh tìm kiếm */}
            <Form className="search-form">
              <FormControl
                type="search"
                placeholder="Shop now bao ship 0đ - Đăng ký ngay!"
                aria-label="Search"
              />
              <Button className="search-button">
                <Search />
              </Button>
            </Form>

            {/* Biểu tượng giỏ hàng */}
            <div className="nav-icons">
              <a href="/cart">
                  <ShoppingCart />
              </a>
            </div>
          </Container>
        </Navbar>
        </div>

        {/* Nội dung trang */}
        <div className="container mt-3">
          <Routes>
            <Route path="/" element={<HomeComponent />} />
            <Route path="/login" element={<LoginComponent />} />
            <Route path="/register" element={<RegisterComponent />} />
            <Route path="/cart" element={<CartComponent />} />
            {currentUser && (
              <>
                <Route path="/profile" element={<ProfileComponent />} />
                <Route path="/profile/:id" element={<ProfileEditComponent />} />
                <Route path="/products" element={<ProductsListComponent />} />
                <Route path="/products/add" element={<AddProductComponent />} />
                <Route path="/products/:id" element={<ProductEditComponent />} />
              </>
            )}
          </Routes>
        </div>
        <ToastContainer />
        <AuthVerify logOut={this.logOut} />
      </>
    );
  }
}

function mapStateToProps(state) {
  const { user } = state.auth;
  return {
    user,
  };
}

export default connect(mapStateToProps)(App);
