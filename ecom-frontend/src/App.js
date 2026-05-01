import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { Container, Navbar, Form, FormControl, Button, Row, Col } from "react-bootstrap";
import { Search, ShoppingCart, Notifications, Help, Language, Facebook, YouTube, Email, Phone, Instagram } from "@mui/icons-material";
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
import { assetUrl } from "./helpers/assetUrl";

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
            <div className="header-top-left">

            </div>
            <div className="header-top-right">
              <button style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}><Notifications /></button>
              <button style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}><Help /></button>
              <button style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}><Language /> Tiếng Việt</button>
              {currentUser ? (
                <>
                  <Link to="/profile" className="auth-links">{currentUser.username}</Link>
                  <button style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }} className="auth-links" onClick={this.logOut}>Đăng Xuất</button>
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
            <Container fluid style={{ padding: '0 60px', display: 'flex', alignItems: 'flex-start' }}>
              {/* Logo combined with text */}
              <Navbar.Brand as={Link} to="/" className="logo-container">
                <img
                  src={assetUrl("/Shop now-logo.png")}
                  alt="Logo"
                  className="logo-image"
                />
                <span className="logo-text">Ecom-Shop123</span>
              </Navbar.Brand>

              {/* Search Container */}
              <div className="search-container-shopee">
                <Form className="search-form">
                  <FormControl
                    type="search"
                    placeholder="Ecom-Shop bao ship 0đ - Đăng ký ngay!"
                    aria-label="Search"
                  />
                  <Button className="search-button">
                    <Search />
                  </Button>
                </Form>
                {/* Keywords gợi ý */}
                <div className="search-keywords">
                  <Link to="/">Dép</Link>
                  <Link to="/">Áo Phông</Link>
                  <Link to="/">Túi Xách</Link>
                  <Link to="/">Váy</Link>
                  <Link to="/">Ốp Điện Thoại</Link>
                  <Link to="/">Tai Nghe</Link>
                  <Link to="/">Mỹ Phẩm</Link>
                  <Link to="/">Giày Nam</Link>
                </div>
              </div>

              {/* Biểu tượng giỏ hàng */}
              <div className="nav-icons">
                <Link to="/cart" title="Giỏ hàng">
                  <ShoppingCart style={{ fontSize: '30px' }} />
                </Link>
              </div>
            </Container>
          </Navbar>
        </div>

        {/* Nội dung trang */}
        <div className="container mt-4 mb-5" style={{ minHeight: '65vh' }}>
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

        {/* Footer Unified Purple */}
        <footer className="bg-light">
          <Container>
            <Row className="g-4">
              <Col lg={3} md={6}>
                <h5>CHĂM SÓC KHÁCH HÀNG</h5>
                <ul className="list-unstyled">
                  <li><Link to="/">Trung Tâm Trợ Giúp</Link></li>
                  <li><Link to="/">Ecom-Shop Blog</Link></li>
                  <li><Link to="/">Ecom-Shop Mall</Link></li>
                  <li><Link to="/">Hướng Dẫn Mua Hàng</Link></li>
                </ul>
              </Col>

              <Col lg={3} md={6}>
                <h5>VỀ ECOM-SHOP</h5>
                <ul className="list-unstyled">
                  <li><Link to="/">Giới Thiệu Về Ecom-Shop</Link></li>
                  <li><Link to="/">Tuyển Dụng</Link></li>
                  <li><Link to="/">Điều Khoản Ecom-Shop</Link></li>
                  <li><Link to="/">Chính Sách Bảo Mật</Link></li>
                </ul>
              </Col>

              <Col lg={3} md={6}>
                <h5>THEO DÕI CHÚNG TÔI</h5>
                <ul className="list-unstyled">
                  <li><a href="https://facebook.com" target="_blank" rel="noreferrer"><Facebook fontSize="small" style={{ marginRight: '8px' }} /> Facebook</a></li>
                  <li><a href="https://instagram.com" target="_blank" rel="noreferrer"><Instagram fontSize="small" style={{ marginRight: '8px' }} /> Instagram</a></li>
                  <li><a href="https://youtube.com" target="_blank" rel="noreferrer"><YouTube fontSize="small" style={{ marginRight: '8px' }} /> YouTube</a></li>
                </ul>
              </Col>

              <Col lg={3} md={6}>
                <h5>LIÊN HỆ</h5>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px' }}>
                  <Email fontSize="small" />
                  <span style={{ fontSize: '14px' }}>support@ecom-shop.devops.io.vn</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
                  <Phone fontSize="small" />
                  <span style={{ fontSize: '14px' }}>+84 123 456 789</span>
                </div>
                <div className="payment-icons">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/5/5e/Visa_Inc._logo.svg" alt="Visa" />
                  <img src="https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg" alt="Mastercard" />
                  <img src="https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png" alt="MoMo" />
                  <img src="https://upload.wikimedia.org/wikipedia/commons/b/b5/PayPal.svg" alt="PayPal" style={{ filter: 'brightness(0) invert(1)' }} />
                </div>
              </Col>
            </Row>
            <hr style={{ borderColor: 'rgba(255,255,255,0.1)' }} />
            <p className="text-center mb-0" style={{ fontSize: '12px', opacity: 0.8 }}>
              &copy; {new Date().getFullYear()} Ecom-Shop. Tất cả các quyền được bảo lưu.
            </p>
          </Container>
        </footer>
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
