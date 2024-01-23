{ config, ... }:
{
  programs.aria2 = {
    enable = true;
    settings = {
      rpc-secret = "nJszuqG+%rs";
      enable-rpc = true;
      # 允许所有来源, web界面跨域权限需要
      rpc-allow-origin-all = true;
      # 允许外部访问，false的话只监听本地端口
      rpc-listen-all = true;
      # 设置代理
      # all-proxy="localhost:7890"
      # 最大同时下载数(任务数), 路由建议值: 3
      max-concurrent-downloads = 5;
      # 断点续传
      continue = true;
      # 同服务器连接数
      max-connection-per-server = 5;
      # 最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
      min-split-size = "10M";
      # 单文件最大线程数, 路由建议值: 5
      split = 10;
      # 下载速度限制
      max-overall-download-limit = 0;
      # 单文件速度限制
      max-download-limit = 0;
      # 上传速度限制
      max-overall-upload-limit = 0;
      # 单文件速度限制
      max-upload-limit = 0;
      # 断开速度过慢的连接
      # lowest-speed-limit=0
      # 文件保存路径, 默认为当前启动位置
      dir = "${config.home.homeDirectory}/Downloads";
    };
  };
}
