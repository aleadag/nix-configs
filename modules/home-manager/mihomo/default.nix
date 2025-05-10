{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    ;

  cfg = config.home-manager.mihomo;

  mkUnit = package: {
    Unit.Description = "mihomo";

    Install.WantedBy = [ "default.target" ];

    Service = {
      ExecStart = "${getExe package} -f ${config.sops.templates."mihomo.yaml".path}";
      Restart = "on-failure";
    };
  };

  mkAgent = package: {
    enable = true;
    config = {
      ProgramArguments = [
        (getExe package)
        "-f"
        config.sops.templates."mihomo.yaml".path
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  mkService = if pkgs.stdenv.isLinux then mkUnit else mkAgent;

  services = {
    mihomo = mkService pkgs.mihomo;
  };
in
{
  options.home-manager.mihomo = {
    enable = lib.mkEnableOption "mihomo service" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf pkgs.stdenv.isLinux { systemd.user.services = services; })
      (mkIf pkgs.stdenv.isDarwin { launchd.agents = services; })
      {
        # 注意规则在满足自己需求情况下，尽量做到精简，不要过度复杂，以免影响性能。
        # https://github.com/qichiyuhub/rule/blob/main/config/mihomo/config.yaml
        sops = {
          secrets = {
            airport1 = { };
            mihomo_secret = { };
          };
          templates."mihomo.yaml".content = # yaml
            ''
              # 锚点定义
              anchors:
                # 健康检查配置
                health_check: &health_check
                  enable: true
                  url: https://www.gstatic.com/generate_204
                  interval: 300

                # 代理选择列表
                proxy_choices: &proxy_choices
                  - "🚀 默认代理"
                  - "⚡ 香港故转"
                  - "⚡ 日本故转"
                  - "🔄 香港自动"
                  - "🔄 日本自动"
                  - "🔄 美国自动"
                  - "🔄 自动选择"
                  - "🇭🇰 香港节点"
                  - "🇯🇵 日本节点"
                  - "🇺🇸 美国节点"
                  - "🌍 全部节点"
                  - "直连"

                # 标准代理组配置
                standard_proxy_group: &standard_proxy_group
                  type: select
                  proxies: *proxy_choices

                # 自动测试配置
                auto_test: &auto_test
                  include-all: true
                  tolerance: 20
                  interval: 300

                # HTTP规则提供者配置
                http_rule_provider: &http_rule_provider
                  type: http
                  interval: 86400

                # 域名规则提供者配置
                domain_rule_provider: &domain_rule_provider
                  <<: *http_rule_provider
                  behavior: domain
                  format: mrs

                # IP规则提供者配置
                ip_rule_provider: &ip_rule_provider
                  <<: *http_rule_provider
                  behavior: ipcidr
                  format: mrs

                # 经典规则提供者配置
                classical_rule_provider: &classical_rule_provider
                  <<: *http_rule_provider
                  behavior: classical
                  format: text

              # 机场订阅
              proxy-providers:
                # for bootstrap, need a proxy to download remote configs
                Local:
                  type: file
                  path: ./local.yaml
                  health-check: *health_check
                Airport1:
                  url: "${config.sops.placeholder.airport1}"
                  type: http
                  interval: 86400
                  health-check: *health_check
                  proxy: 直连

              # 节点信息
              proxies:
                - name: 直连
                  type: direct

              # 全局配置
              mixed-port: 7890
              port: 7891
              socks-port: 7892
              allow-lan: true
              bind-address: '*'
              ipv6: false
              unified-delay: true
              tcp-concurrent: true
              log-level: warning
              find-process-mode: "off"
              # interface-name: en0
              global-client-fingerprint: chrome
              keep-alive-idle: 600
              keep-alive-interval: 15
              disable-keep-alive: false
              profile:
                store-selected: true
                store-fake-ip: true

              # 控制面板
              external-controller: 0.0.0.0:9090
              secret: ${config.sops.placeholder.mihomo_secret}
              external-ui: ./ui
              external-ui-url: https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip

              # 嗅探
              sniffer:
                enable: true
                sniff:
                  HTTP:
                    ports:
                      - 80
                      - 8080-8880
                    override-destination: true
                  TLS:
                    ports:
                      - 443
                      - 8443
                  QUIC:
                    ports:
                      - 443
                      - 8443
                force-domain:
                  - +.v2ex.com
                skip-domain:
                  - +.baidu.com

              # 入站
              tun:
                enable: true
                # system/gvisor/mixed
                stack: mixed
                dns-hijack:
                  - any:53
                  - tcp://any:53
                auto-route: true
                auto-redirect: true
                auto-detect-interface: true

              # DNS模块
              dns:
                enable: true
                listen: 0.0.0.0:1053
                ipv6: false
                respect-rules: true
                enhanced-mode: fake-ip
                fake-ip-range: 28.0.0.1/8
                fake-ip-filter-mode: blacklist
                fake-ip-filter:
                  - rule-set:private_domain,cn_domain
                  - +.msftconnecttest.com
                  - +.msftncsi.com
                  - time.*.com
                default-nameserver:
                  - 223.5.5.5
                proxy-server-nameserver:
                  - https://223.5.5.5/dns-query
                # namesever尽量用运营商提供的DNS
                nameserver:
                  - 223.5.5.5
                  - 119.29.29.29

              # 出站策略
              proxy-groups:
                - name: "🚀 默认代理"
                  type: select
                  proxies:
                    - "⚡ 香港故转"
                    - "⚡ 日本故转"
                    - "🔄 香港自动"
                    - "🔄 日本自动"
                    - "🔄 美国自动"
                    - "🔄 自动选择"
                    - "🇭🇰 香港节点"
                    - "🇯🇵 日本节点"
                    - "🇺🇸 美国节点"
                    - "🌍 全部节点"
                    - "直连"

                - name: "▶️ YouTube"
                  <<: *standard_proxy_group

                - name: "🔎 Google"
                  <<: *standard_proxy_group

                - name: "🤖 ChatGPT"
                  <<: *standard_proxy_group

                - name: "🐙 GitHub"
                  <<: *standard_proxy_group

                - name: "☁️ OneDrive"
                  <<: *standard_proxy_group

                - name: "🪟 Microsoft"
                  <<: *standard_proxy_group

                - name: "📱 TikTok"
                  <<: *standard_proxy_group

                - name: "✈️ Telegram"
                  <<: *standard_proxy_group

                - name: "🎬 NETFLIX"
                  <<: *standard_proxy_group

                - name: "🚄 Speedtest"
                  <<: *standard_proxy_group

                - name: "💰 PayPal"
                  <<: *standard_proxy_group

                - name: "🍎 Apple"
                  type: select
                  proxies:
                    - 直连
                    - "🚀 默认代理"

                - name: "🔰 直连"
                  type: select
                  proxies:
                    - 直连
                    - "🚀 默认代理"

                - name: "🐠 漏网之鱼"
                  <<: *standard_proxy_group

                - name: "🇭🇰 香港节点"
                  type: select
                  include-all: true
                  filter: (?i)港|hk|hongkong|hong kong

                - name: "🇯🇵 日本节点"
                  type: select
                  include-all: true
                  filter: (?i)日|jp|japan

                - name: "🇺🇸 美国节点"
                  type: select
                  include-all: true
                  filter: (?i)美|us|unitedstates|united states

                - name: "⚡ 香港故转"
                  type: fallback
                  <<: *auto_test
                  filter: (?=.*(港|HK|(?i)Hong))^((?!(台|日|韩|新|深|美)).)*$

                - name: "⚡ 日本故转"
                  type: fallback
                  <<: *auto_test
                  filter: (?=.*(日|JP|(?i)Japan))^((?!(港|台|韩|新|美)).)*$

                - name: "🔄 香港自动"
                  type: url-test
                  <<: *auto_test
                  filter: (?=.*(港|HK|(?i)Hong))^((?!(台|日|韩|新|深|美)).)*$

                - name: "🔄 日本自动"
                  type: url-test
                  <<: *auto_test
                  filter: (?=.*(日|JP|(?i)Japan))^((?!(港|台|韩|新|美)).)*$

                - name: "🔄 美国自动"
                  type: url-test
                  <<: *auto_test
                  filter: (?=.*(美|US|(?i)States|America))^((?!(港|台|日|韩|新)).)*$

                - name: "🔄 自动选择"
                  type: url-test
                  <<: *auto_test
                  filter: ^((?!(直连)).)*$

                - name: "🌍 全部节点"
                  type: select
                  include-all: true

              # 规则匹配
              # 此规则部分没有做防泄露处理，因为弊严重大于利！
              rules:
                - DOMAIN-SUFFIX,qichiyu.com,🚀 默认代理
                - RULE-SET,private_ip,🔰 直连
                - RULE-SET,private_domain,🔰 直连
                - RULE-SET,apple_domain,🍎 Apple
                - RULE-SET,proxylite,🚀 默认代理
                - RULE-SET,ai,🤖 ChatGPT
                - RULE-SET,github_domain,🐙 GitHub
                - RULE-SET,youtube_domain,▶️ YouTube
                - RULE-SET,google_domain,🔎 Google
                - RULE-SET,onedrive_domain,☁️ OneDrive
                - RULE-SET,microsoft_domain,🪟 Microsoft
                - RULE-SET,tiktok_domain,📱 TikTok
                - RULE-SET,speedtest_domain,🚄 Speedtest
                - RULE-SET,telegram_domain,✈️ Telegram
                - RULE-SET,netflix_domain,🎬 NETFLIX
                - RULE-SET,paypal_domain,💰 PayPal
                - RULE-SET,gfw_domain,🚀 默认代理
                - RULE-SET,geolocation-!cn,🚀 默认代理
                - RULE-SET,cn_domain,🔰 直连
                - RULE-SET,google_ip,🔎 Google,no-resolve
                - RULE-SET,netflix_ip,🎬 NETFLIX,no-resolve
                - RULE-SET,telegram_ip,✈️ Telegram,no-resolve
                - RULE-SET,cn_ip,🔰 直连
                - MATCH,🐠 漏网之鱼

              # 规则集
              rule-providers:
                private_ip:
                  <<: *ip_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/private.mrs
                private_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs

                proxylite:
                  <<: *classical_rule_provider
                  url: https://raw.githubusercontent.com/qichiyuhub/rule/refs/heads/main/proxy.list

                ai:
                  <<: *domain_rule_provider
                  url: https://github.com/MetaCubeX/meta-rules-dat/raw/refs/heads/meta/geo/geosite/category-ai-!cn.mrs

                youtube_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/youtube.mrs

                google_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/google.mrs

                github_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/github.mrs

                telegram_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs

                netflix_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/netflix.mrs

                paypal_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/paypal.mrs

                onedrive_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/onedrive.mrs

                microsoft_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/microsoft.mrs

                apple_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/apple-cn.mrs

                speedtest_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/ookla-speedtest.mrs

                tiktok_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/tiktok.mrs

                gfw_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/gfw.mrs

                geolocation-!cn:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/geolocation-!cn.mrs

                cn_domain:
                  <<: *domain_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/cn.mrs

                cn_ip:
                  <<: *ip_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/cn.mrs

                google_ip:
                  <<: *ip_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/google.mrs

                telegram_ip:
                  <<: *ip_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/telegram.mrs

                netflix_ip:
                  <<: *ip_rule_provider
                  url: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/netflix.mrs
            '';
        };
      }
    ]
  );
}
