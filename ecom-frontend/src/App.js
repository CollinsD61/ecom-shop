import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { Container, Navbar, Form, FormControl, Button, Row, Col } from "react-bootstrap";
import { Search, ShoppingCart, Notifications, Help, Language, Facebook, YouTube, Email, Phone, Send, AccountCircle, Instagram } from "@mui/icons-material";
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
        <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@300;400;500;600;700&family=Outfit:wght@300;400;500;600&family=Playfair+Display:ital,wght@0,500;0,700;0,800;1,500&display=swap" rel="stylesheet" />
        <div className="header-container">
        {/* Header Top - Tầng 1 (Shopee Style) */}
        <div className="header-top">
          <div className="header-top-left">
            <a href="/">Kênh Người Bán</a>
            <div style={{width:'1px', height:'13px', background:'rgba(255,255,255,0.2)'}}></div>
            <a href="/">Trở thành Người bán Shopee</a>
            <div style={{width:'1px', height:'13px', background:'rgba(255,255,255,0.2)'}}></div>
            <a href="/">Tải ứng dụng</a>
            <div style={{width:'1px', height:'13px', background:'rgba(255,255,255,0.2)'}}></div>
            <div style={{display:'flex', alignItems:'center', gap:'8px'}}>
              Kết nối 
              <a href="/"><Facebook fontSize="small" /></a>
              <a href="/"><Instagram fontSize="small" /></a>
            </div>
          </div>
          <div className="header-top-right">
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}} title="Thông báo"><Notifications fontSize="small" /> Thông báo</button>
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}} title="Hỗ trợ"><Help fontSize="small" /> Hỗ trợ</button>
            <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}}><Language fontSize="small" /> Tiếng Việt</button>
            {currentUser ? (
              <>
                <Link to="/profile" className="auth-links" style={{display:'flex', alignItems:'center', gap:'4px'}}>
                  <AccountCircle fontSize="small" /> {currentUser.username}
                </Link>
                <button style={{background:'none', border:'none', color:'inherit', cursor:'pointer'}} className="auth-links" onClick={this.logOut}>Đăng Xuất</button>
              </>
            ) : (
              <>
                <Link to="/register" className="auth-links">Đăng Ký</Link>
                <div style={{width:'1px', height:'13px', background:'rgba(255,255,255,0.2)'}}></div>
                <Link to="/login" className="auth-links">Đăng Nhập</Link>
              </>
            )}
          </div>
        </div>

        {/* Navbar - Tầng 2 (Shopee Style) */}
        <Navbar expand="lg" className="navbar">
          <Container fluid style={{padding: '0 60px', display: 'flex', alignItems: 'flex-start'}}>
            {/* Logo logotype 'Ecom-Shop' - White */}
            <Navbar.Brand as={Link} to="/" style={{display: 'flex', alignItems: 'center', textDecoration: 'none', marginTop: '5px'}}>
              <div style={{
                fontFamily: 'var(--font-display)',
                fontWeight: 800,
                fontSize: '32px',
                color: '#fff',
                display: 'flex',
                alignItems: 'center'
              }}>
                Ecom-Shop
              </div>
            </Navbar.Brand>

            {/* Thanh tìm kiếm - Trung tâm & Thu gọn */}
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
                <a href="/">Dép</a>
                <a href="/">Áo Phông</a>
                <a href="/">Túi Xách</a>
                <a href="/">Váy</a>
                <a href="/">Ốp Điện Thoại</a>
                <a href="/">Tai Nghe</a>
                <a href="/">Mỹ Phẩm</a>
              </div>
            </div>

            {/* Biểu tượng giỏ hàng */}
            <div className="nav-icons">
              <Link to="/cart" title="Giỏ hàng">
                  <ShoppingCart style={{fontSize: '28px'}} />
              </Link>
            </div>
          </Container>
        </Navbar>
        </div>

        {/* Nội dung trang */}
        <div className="container mt-4 mb-5" style={{minHeight: '60vh'}}>
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

        {/* Footer Redesign */}
        <footer className="bg-light py-5">
          <Container>
            <Row className="g-4">
              {/* Cột 1: About Us */}
              <Col lg={3} md={6}>
                <h5 style={{color: '#F3E5F5'}}>About Us</h5>
                <p style={{fontSize: '14px', lineHeight: '1.6', marginBottom: '20px', color: 'rgba(255, 255, 255, 0.7)'}}>
                  Ecom-Shop là nền tảng thương mại điện tử hiện đại, mang đến trải nghiệm mua sắm sang trọng và tiện lợi.
                </p>
                <div style={{fontSize: '14px', display:'flex', flexDirection:'column', gap:'10px', color: 'rgba(255, 255, 255, 0.7)'}}>
                  <div style={{display:'flex', alignItems:'center', gap:'10px'}}>
                    <Email fontSize="small" style={{color:'var(--color-lavender-light)'}} /> 
                    <span>support@ecom-shop.devops.io.vn</span>
                  </div>
                  <div style={{display:'flex', alignItems:'center', gap:'10px'}}>
                    <Phone fontSize="small" style={{color:'var(--color-lavender-light)'}} /> 
                    <span>+84 123 456 789</span>
                  </div>
                </div>
              </Col>

              {/* Cột 2: Quick Links */}
              <Col lg={3} md={6}>
                <h5 style={{color: '#F3E5F5'}}>Quick Links</h5>
                <ul className="list-unstyled" style={{fontSize: '14px', display:'flex', flexDirection:'column', gap:'12px'}}>
                  <li><Link to="/" style={{color: 'rgba(255, 255, 255, 0.7)', textDecoration: 'none'}}>Trang Chủ</Link></li>
                  <li><Link to="/products" style={{color: 'rgba(255, 255, 255, 0.7)', textDecoration: 'none'}}>Sản Phẩm</Link></li>
                  <li><Link to="/profile" style={{color: 'rgba(255, 255, 255, 0.7)', textDecoration: 'none'}}>Tài Khoản</Link></li>
                  <li><Link to="/cart" style={{color: 'rgba(255, 255, 255, 0.7)', textDecoration: 'none'}}>Giỏ Hàng</Link></li>
                </ul>
              </Col>

              {/* Cột 3: Bản tin */}
              <Col lg={3} md={6}>
                <h5 style={{color: '#F3E5F5'}}>Bản tin</h5>
                <p style={{fontSize: '14px', marginBottom: '15px', color: 'rgba(255, 255, 255, 0.7)'}}>Đăng ký để nhận thông tin khuyến mãi mới nhất từ chúng tôi.</p>
                <Form className="d-flex" style={{gap: '5px'}}>
                  <FormControl
                    type="email"
                    placeholder="Email của bạn"
                    style={{fontSize: '13px', borderRadius: '4px', border: 'none'}}
                  />
                  <Button style={{
                    background: 'var(--color-gold)', 
                    border: 'none', 
                    borderRadius: '4px',
                    padding: '0 15px'
                  }}>
                    <Send fontSize="small" />
                  </Button>
                </Form>
              </Col>

              {/* Cột 4: Follow Us & Payment */}
              <Col lg={3} md={6}>
                <h5 style={{color: '#F3E5F5'}}>Follow Us & Payment</h5>
                <div className="d-flex gap-3 mb-4">
                  <a href="https://facebook.com" target="_blank" rel="noreferrer" style={{color: 'rgba(255, 255, 255, 0.7)'}}><Facebook /></a>
                  <a href="https://youtube.com" target="_blank" rel="noreferrer" style={{color: 'rgba(255, 255, 255, 0.7)'}}><YouTube /></a>
                </div>
                <div className="d-flex flex-wrap gap-2 mt-3">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/5/5e/Visa_Inc._logo.svg" alt="Visa" height="20" style={{filter: 'brightness(0) invert(1)', opacity: 0.8}} />
                  <img src="https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg" alt="Mastercard" height="20" style={{opacity: 0.8}} />
                  <img src="https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png" alt="MoMo" height="20" style={{borderRadius: '4px'}} />
                  <img src="https://upload.wikimedia.org/wikipedia/commons/b/b5/PayPal.svg" alt="PayPal" height="20" style={{filter: 'brightness(0) invert(1)', opacity: 0.8}} />
                </div>
              </Col>
            </Row>
            <hr style={{margin: '40px 0 20px', borderColor: 'rgba(255,255,255,0.1)'}} />
            <p className="text-center mb-0" style={{fontSize: '13px', opacity: 0.7, color: 'rgba(255, 255, 255, 0.7)'}}>
              &copy; {new Date().getFullYear()} Ecom-Shop - devops.io.vn. All rights reserved.
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
