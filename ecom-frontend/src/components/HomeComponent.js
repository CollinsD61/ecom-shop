import React, { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import { Container, Box, Typography, IconButton, Grid, Button } from "@mui/material";
import { ShoppingCartRounded } from "@mui/icons-material";
import { Carousel } from "react-bootstrap";
import productService from "../services/ProductService";
import cartService from "../services/CartService";
import { toast } from 'react-toastify';
import { Card } from "react-bootstrap";
import 'react-toastify/dist/ReactToastify.css';
import { assetUrl } from "../helpers/assetUrl";

const categories = [
  { name: "Thời Trang Nam", image: "/thoi-trang-nam.png" },
  { name: "Điện Thoại & Phụ Kiện", image: "/dien-thoai-phu-kien.png" },
  { name: "Thiết Bị Điện Tử", image: "/thiet-bi-dien-tu.png" },
  { name: "Máy Tính & Laptop", image: "/may-tinh-lap-top.png" },
  { name: "Đồ Gia Dụng", image: "/nha-cua-doi-song.png" },
  { name: "Sắc Đẹp", image: "/sac-dep.png" },
  { name: "Đồng Hồ", image: "/dong-ho.png" },
  { name: "Giày Dép Nam", image: "/giay-dep-nam.png" },
  { name: "Mẹ & Bé", image: "/me-va-be.png" },
];

export default function Home() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const itemsPerPage = 6;
  const [featuredProducts, setFeaturedProducts] = useState([]);
  const [cartId, setCartId] = useState(null);
  // Removed unused currentProduct state


  useEffect(() => {
    retrieveProducts();
    retrieveCart();
  }, []);

  const handleNext = () => {
    if (currentIndex + itemsPerPage < categories.length) {
      setCurrentIndex(currentIndex + itemsPerPage);
    }
  };

  const handlePrev = () => {
    if (currentIndex - itemsPerPage >= 0) {
      setCurrentIndex(currentIndex - itemsPerPage);
    }
  };

  const retrieveProducts = () => {
    productService.getAll()
      .then((response) => {
        setFeaturedProducts(response.data.slice(0, 8));
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const retrieveCart = async () => {
    const user = localStorage.getItem("user");
    if (!user) {
      console.error("User not found in localStorage");
      return; // Hoặc xử lý hợp lý hơn như chuyển hướng đến trang đăng nhập
    }

    const parsedUser = JSON.parse(user);

    try {
      const response = await cartService.getByName(parsedUser.username);
      setCartId(response.data.id);
    } catch (e) {
      cartService.create(parsedUser.username)
        .then((response) => {
          setCartId(response.data.id);
        })
        .catch((e) => {
          console.log(e);
        });
    }
  };


  const addToCart = (product) => {
    cartService.addProducts(cartId, [product])
      .then(() => {
        toast(`${product.name} added to cart`);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  // Removed unused setActiveProduct
  const formatCurrency = (amount) => {
    const number = Number(amount) || 0;
    return number.toLocaleString("vi-VN");
  };

  const productImageMap = {
    "Áo len ren màu hồng cardigan nữ": "ao-len-nu.png",
    "Điện thoại Apple iPhone 15 Pro Max 256GB": "iphone-15-promax.png",
    "Nike Air Jordan 1 Mid Chicago Toe Like Auth": "giay-nike-air.png",
    "MacBook Pro 14 inch M4 2024": "macbook-m4-pro.png",
    "Gel Rửa Mặt Emmié Soothing": "sua-rua-mat.png",
    "Quần Tập Gym Nữ Cạp Chéo": "quan-tap-gym-nu.png",
    "Dép đi trong nhà siêu xinh nam nữ": "dep-di-trong-nha.png",
    "Máy giặt Electrolux Inverter 11 kg": "may-giat.png",
  };

  const displayedCategories = categories.slice(currentIndex, currentIndex + itemsPerPage);

  return (
    <Container>
      {/* Banner */}
      <Box className="text-center my-4 home-carousel">
        <Carousel>
          <Carousel.Item>
            <img className="d-block w-100 img-fluid home-carousel-image" src={assetUrl("slide-4.png")} alt="Slide 4" />
          </Carousel.Item>
          <Carousel.Item>
            <img className="d-block w-100 img-fluid home-carousel-image" src={assetUrl("slide-0.png")} alt="Slide 0" />
          </Carousel.Item>
          <Carousel.Item>
            <img className="d-block w-100 img-fluid home-carousel-image" src={assetUrl("slide-1.png")} alt="Slide 1" />
          </Carousel.Item>
          <Carousel.Item>
            <img className="d-block w-100 img-fluid home-carousel-image" src={assetUrl("slide-2.png")} alt="Slide 2" />
          </Carousel.Item>
          <Carousel.Item>
            <img className="d-block w-100 img-fluid home-carousel-image" src={assetUrl("slide-3.png")} alt="Slide 3" />
          </Carousel.Item>
        </Carousel>
      </Box>

      {/* Icon Menu */}
      <Grid container spacing={2} justifyContent="center" className="mb-4">
        {["Hàng Chọn Giá Hời", "Mã Giảm Giá", "Miễn Phí Ship", "Hàng quốc tế"].map((menu, index) => (
          <Grid item xs={4} md={2} key={index} className="text-center">
            <Typography>{menu}</Typography>
          </Grid>
        ))}
      </Grid>

      {/* Danh Mục */}
      <Typography variant="h5" className="mb-3" align="center">
        DANH MỤC
      </Typography>

      {/* Slider Danh Mục */}
      <Box display="flex" alignItems="center" justifyContent="space-between">
        <IconButton onClick={handlePrev} disabled={currentIndex === 0}>
          &lt;
        </IconButton>
        <Grid container spacing={3} justifyContent="center" className="d-flex flex-wrap">
          {displayedCategories.map((category, index) => (
            <Grid item xs={6} sm={4} md={2} key={index} className="text-center">
              <img
                src={assetUrl(category.image)}
                alt={category.name}
                className="rounded-circle mb-2 img-fluid category-image"
              />
              <Typography>{category.name}</Typography>
            </Grid>
          ))}
        </Grid>
        <IconButton onClick={handleNext} disabled={currentIndex + itemsPerPage >= categories.length}>
          &gt;
        </IconButton>
      </Box>

      {/* Sản Phẩm Nổi Bật */}
      <Typography variant="h5" className="mb-3 mt-5" align="center">
        SẢN PHẨM NỔI BẬT
      </Typography>
      <div className="row row-cols-1 row-cols-md-4 g-4">
        {featuredProducts &&
          featuredProducts.map((product, index) => (
            <div key={index} className="col">
              <Card className="product-card">
                <Card.Img
                  variant="top"
                  src={assetUrl(productImageMap[product.name] || "placeholder.png")}
                />
                <Card.Body className="product-card-body">
                  <Card.Title className="product-card-title">
                    {product.name}
                  </Card.Title>
                  <Card.Subtitle className="mb-2 text-muted product-card-subtitle">
                    {product.category}
                  </Card.Subtitle>
                  <Card.Text className="product-card-desc">
                    {product.description.length > 60
                      ? product.description.substring(0, 60) + "..."
                      : product.description}
                  </Card.Text>
                  <div className="product-card-bottom">
                    <Card.Text className="product-card-price">
                      {formatCurrency(product.price)} VNĐ
                    </Card.Text>
                    <Button
                      startIcon={<ShoppingCartRounded />}
                      variant="contained"
                      className="product-card-button"
                      onClick={() => addToCart(product)}
                    >
                      Add to Cart
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            </div>
          ))}
      </div>
    </Container>
  );
}
