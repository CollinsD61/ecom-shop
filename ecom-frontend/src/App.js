import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { Container, Navbar, Form, FormControl, Button } from "react-bootstrap";
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


    return (
      <>
        {/* Font import */}
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600&family=Playfair+Display:ital,wght@0,500;0,700;0,800;1,500&display=swap" rel="stylesheet" />
        <div className="header-container">
        {/* Header Top */}
        <div className="header-top">
          <div>
            <a href="https://devopsedu.vn/contact/" target="_blank" rel="noopener noreferrer">Trở thành người đóng góp</a>
            <a href="https://devopsedu.vn/blog/" target="_blank" rel="noopener noreferrer">Tài liệu tham khảo</a>
            <a href="https://m.me/139689492555066" target="_blank" rel="noopener noreferrer">Liên hệ</a>
          </div>
          <div>
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}}><Notifications /></button>
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}}><Help /></button>
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}}><Language /> Tiếng Việt</button>
            {currentUser ? (
              <>
                <Link to="/profile" className="auth-links">{currentUser.username}</Link>
                <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}} className="auth-links" onClick={this.logOut}>Đăng Xuất</button>
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
