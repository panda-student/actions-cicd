# 构建阶段
FROM node:16-alpine as builder

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制项目文件
COPY . .

# 构建项目
RUN npm run build

# 运行阶段
FROM nginx:alpine

# 复制构建产物到Nginx的静态文件目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制自定义的Nginx配置文件（可选）
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露80端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]