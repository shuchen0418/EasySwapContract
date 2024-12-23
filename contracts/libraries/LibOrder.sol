// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Price} from "./RedBlackTreeLibrary.sol";

type OrderKey is bytes32;

library LibOrder {
    enum Side {
        List, // 列出订单
        Bid   // 出价订单
    }

    enum SaleKind {
        FixedPriceForCollection, // 固定价格出售整个收藏
        FixedPriceForItem        // 固定价格出售单个物品
    }

    // 资产结构体，表示NFT的基本信息
    struct Asset {
        uint256 tokenId;     // NFT的标识符
        address collection;  // NFT所属的Collection合约地址
        uint96 amount;       // NFT的数量
    }

    // NFT信息结构体，包含NFT的合约地址和标识符
    struct NFTInfo {
        address collection;  // NFT所属的合约地址
        uint256 tokenId;     // NFT的标识符
    }

    // 订单结构体，包含订单的详细信息
    struct Order {
        Side side;           // 订单的类型（列出或出价）
        SaleKind saleKind;   // 销售类型（固定价格）
        address maker;       // 订单创建者的地址
        Asset nft;           // 订单中涉及的NFT资产
        Price price;         // NFT的单价
        uint64 expiry;       // 订单的过期时间
        uint64 salt;         // 订单的随机数，用于防止哈希碰撞
    }

    // 数据库订单结构体，包含订单和下一个订单的键
    struct DBOrder {
        Order order;         // 订单的详细信息
        OrderKey next;       // 下一个订单的键
    }

    /// @dev 订单队列结构体，用于存储相同价格的订单
    struct OrderQueue {
        OrderKey head;       // 队列头部的订单键
        OrderKey tail;       // 队列尾部的订单键
    }

    // 编辑详情结构体，包含需要编辑的旧订单键和新的订单信息
    struct EditDetail {
        OrderKey oldOrderKey; // 需要编辑的旧订单键
        LibOrder.Order newOrder; // 需要添加的新订单结构体
    }

    // 匹配详情结构体，包含卖单和买单的信息
    struct MatchDetail {
        LibOrder.Order sellOrder; // 卖单的详细信息
        LibOrder.Order buyOrder;  // 买单的详细信息
    }

    OrderKey public constant ORDERKEY_SENTINEL = OrderKey.wrap(0x0);

    bytes32 public constant ASSET_TYPEHASH =
        keccak256("Asset(uint256 tokenId,address collection,uint96 amount)");

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint8 side,uint8 saleKind,address maker,Asset nft,uint128 price,uint64 expiry,uint64 salt)Asset(uint256 tokenId,address collection,uint96 amount)"
        );

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPEHASH,
                    asset.tokenId,
                    asset.collection,
                    asset.amount
                )
            );
    }

    function hash(Order memory order) internal pure returns (OrderKey) {
        return
            OrderKey.wrap(
                keccak256(
                    abi.encodePacked(
                        ORDER_TYPEHASH,
                        order.side,
                        order.saleKind,
                        order.maker,
                        hash(order.nft),
                        Price.unwrap(order.price),
                        order.expiry,
                        order.salt
                    )
                )
            );
    }

    function isSentinel(OrderKey orderKey) internal pure returns (bool) {
        return OrderKey.unwrap(orderKey) == OrderKey.unwrap(ORDERKEY_SENTINEL);
    }

    function isNotSentinel(OrderKey orderKey) internal pure returns (bool) {
        return OrderKey.unwrap(orderKey) != OrderKey.unwrap(ORDERKEY_SENTINEL);
    }
}
