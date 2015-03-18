﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using PmsNCRWcf.Model;
using Brilliantech.Framwork.Utils.LogUtil;
using System.ServiceModel.Web;
using PmsNCRWcf.Config;
using RestSharp;
using PmsNCRWcf.Helper;

namespace PmsNCRWcf
{
    public class OrderService:IOrderService
    { 
        public Msg<OrderItemCheck> GetOrderItemForCheck(string machineNr)
        {
            Msg<OrderItemCheck> msg = new Msg<OrderItemCheck>();
            try
            {
                var req = new RestRequest(ApiConfig.OrderFirstForProduceAction, Method.GET);
                req.RequestFormat = DataFormat.Json;
                req.AddParameter("machine_nr", machineNr);
                var res = new ApiClient().Execute(req);
                var data = JSONHelper.parse<OrderItemCheck>(res.Content);
                if (data != null)
                { 
                    msg.Result = true;
                    msg.Object = data;
                }
                else
                {
                    msg.Content = "不存在需要生产的订单，请联系相关人员";
                }
            }
            catch (Exception e) {
                msg.Result = false;
                msg.Content = e.Message;
                LogUtil.Logger.Error(e.Message);
            }
            return msg;
        }


        private bool setHead()
        {
            WebOperationContext.Current.OutgoingResponse.Headers.Add("Access-Control-Allow-Origin", "*");
            if (WebOperationContext.Current.IncomingRequest.Method == "OPTIONS")
            {
                WebOperationContext.Current.OutgoingResponse.Headers
                    .Add("Access-Control-Allow-Methods", "POST, OPTIONS, GET");
                WebOperationContext.Current.OutgoingResponse.Headers
                    .Add("Access-Control-Allow-Headers",
                         "Content-Type, Accept, Authorization, x-requested-with");
                return false;
            }
            return true;
        }
    }
}
