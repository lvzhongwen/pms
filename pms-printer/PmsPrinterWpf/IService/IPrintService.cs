﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using PmsPrinterWpf.Model;

namespace PmsPrinterWpf.IService
{
    public interface IPrintService
    {
        Msg<string> Print(string code, string id, string printer_name = null, string copy = null);
    }
}
