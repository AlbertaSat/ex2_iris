#include <stdbool.h>

bool isCloud(float b, float r, float nir, float swir) {
    if (b <= 0.2616838663816452f) {
        if (b <= 0.18350715935230255f) {
            if (b <= 0.15572862327098846f) {
                if (nir <= 0.1685667410492897f) {
                    if (r <= 0.1215934082865715f) {
                        if (r <= 0.1018952950835228f) {
                            return false;
                        } else {
                            if (nir <= 0.1330953985452652f) {
                                if (swir <= 0.09109343215823174f) {
                                    return true;
                                } else {
                                    if (b <= 0.131435327231884f) {
                                        if (swir <= 0.10173411667346954f) {
                                            if (r <= 0.1076790988445282f) {
                                                if (b <= 0.11768569052219391f) {
                                                    return true;
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                if (nir <= 0.11504844948649406f) {
                                                    return false;
                                                } else {
                                                    return true;
                                                }
                                            }
                                        } else {
                                            if (r <= 0.11919023841619492f) {
                                                return false;
                                            } else {
                                                return true;
                                            }
                                        }
                                    } else {
                                        return false;
                                    }
                                }
                            } else {
                                return false;
                            }
                        }
                    } else {
                        if (swir <= 0.1229896992444992f) {
                            if (swir <= 0.0954805389046669f) {
                                if (r <= 0.1380484402179718f) {
                                    if (b <= 0.13567355275154114f) {
                                        if (swir <= 0.08828428387641907f) {
                                            return false;
                                        } else {
                                            if (nir <= 0.13842519372701645f) {
                                                return true;
                                            } else {
                                                return false;
                                            }
                                        }
                                    } else {
                                        return false;
                                    }
                                } else {
                                    if (swir <= 0.08987395837903023f) {
                                        return false;
                                    } else {
                                        if (swir <= 0.09282263368368149f) {
                                            return true;
                                        } else {
                                            return false;
                                        }
                                    }
                                }
                            } else {
                                if (b <= 0.14432980865240097f) {
                                    if (swir <= 0.11131089553236961f) {
                                        if (b <= 0.137241892516613f) {
                                            if (nir <= 0.1304190531373024f) {
                                                return false;
                                            } else {
                                                if (nir <= 0.1485811173915863f) {
                                                    return true;
                                                } else {
                                                    if (r <= 0.12536748498678207f) {
                                                        return false;
                                                    } else {
                                                        return true;
                                                    }
                                                }
                                            }
                                        } else {
                                            if (r <= 0.1292107179760933f) {
                                                return false;
                                            } else {
                                                return true;
                                            }
                                        }
                                    } else {
                                        if (r <= 0.13243908435106277f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    }
                                } else {
                                    if (r <= 0.14032947272062302f) {
                                        if (nir <= 0.1317063644528389f) {
                                            return true;
                                        } else {
                                            return false;
                                        }
                                    } else {
                                        if (b <= 0.15405497699975967f) {
                                            if (r <= 0.1489717811346054f) {
                                                return true;
                                            } else {
                                                return false;
                                            }
                                        } else {
                                            if (r <= 0.14317549020051956f) {
                                                return false;
                                            } else {
                                                return true;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            return true;
                        }
                    }
                } else {
                    return false;
                }
            } else {
                if (swir <= 0.17161446064710617f) {
                    if (r <= 0.1467537209391594f) {
                        return true;
                    } else {
                        if (swir <= 0.09122516214847565f) {
                            return false;
                        } else {
                            if (swir <= 0.09530062228441238f) {
                                if (b <= 0.16910938173532486f) {
                                    if (nir <= 0.17432628571987152f) {
                                        return true;
                                    } else {
                                        return false;
                                    }
                                } else {
                                    return false;
                                }
                            } else {
                                if (swir <= 0.13254816830158234f) {
                                    if (nir <= 0.15733032673597336f) {
                                        if (r <= 0.15215881913900375f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    } else {
                                        if (nir <= 0.18281875550746918f) {
                                            if (swir <= 0.11320330575108528f) {
                                                if (swir <= 0.1018667034804821f) {
                                                    if (b <= 0.1593920737504959f) {
                                                        return true;
                                                    } else {
                                                        return false;
                                                    }
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                return true;
                                            }
                                        } else {
                                            return true;
                                        }
                                    }
                                } else {
                                    if (b <= 0.16637111455202103f) {
                                        return true;
                                    } else {
                                        if (nir <= 0.20772482454776764f) {
                                            if (b <= 0.17534811049699783f) {
                                                if (r <= 0.1608622893691063f) {
                                                    if (nir <= 0.1744132563471794f) {
                                                        return false;
                                                    } else {
                                                        if (nir <= 0.19500765949487686f) {
                                                            return true;
                                                        } else {
                                                            return false;
                                                        }
                                                    }
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                if (nir <= 0.18375881761312485f) {
                                                    if (swir <= 0.14265763759613037f) {
                                                        return false;
                                                    } else {
                                                        return true;
                                                    }
                                                } else {
                                                    return true;
                                                }
                                            }
                                        } else {
                                            return true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    return true;
                }
            }
        } else {
            if (swir <= 0.130018413066864f) {
                if (swir <= 0.1084778793156147f) {
                    return false;
                } else {
                    if (b <= 0.2179376408457756f) {
                        if (r <= 0.17570822685956955f) {
                            if (nir <= 0.16281570494174957f) {
                                return true;
                            } else {
                                if (nir <= 0.25475989282131195f) {
                                    if (b <= 0.19685833901166916f) {
                                        if (r <= 0.15951097756624222f) {
                                            return false;
                                        } else {
                                            if (nir <= 0.1932307630777359f) {
                                                if (nir <= 0.17957039922475815f) {
                                                    return true;
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                return true;
                                            }
                                        }
                                    } else {
                                        return false;
                                    }
                                } else {
                                    return true;
                                }
                            }
                        } else {
                            if (nir <= 0.18417301028966904f) {
                                return true;
                            } else {
                                if (swir <= 0.1172850951552391f) {
                                    return false;
                                } else {
                                    if (b <= 0.19451767206192017f) {
                                        return false;
                                    } else {
                                        if (r <= 0.20806267112493515f) {
                                            return true;
                                        } else {
                                            return false;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (r <= 0.21827813982963562f) {
                            if (b <= 0.22592248022556305f) {
                                if (r <= 0.19194677472114563f) {
                                    return false;
                                } else {
                                    if (swir <= 0.1237867884337902f) {
                                        return false;
                                    } else {
                                        return true;
                                    }
                                }
                            } else {
                                return false;
                            }
                        } else {
                            return true;
                        }
                    }
                }
            } else {
                if (swir <= 0.24454279243946075f) {
                    if (b <= 0.19991427659988403f) {
                        if (swir <= 0.19206351041793823f) {
                            if (nir <= 0.22366202622652054f) {
                                if (swir <= 0.13743160665035248f) {
                                    if (r <= 0.17667649686336517f) {
                                        return true;
                                    } else {
                                        return false;
                                    }
                                } else {
                                    return true;
                                }
                            } else {
                                if (r <= 0.1986062154173851f) {
                                    if (swir <= 0.15185333043336868f) {
                                        return false;
                                    } else {
                                        if (b <= 0.1893436312675476f) {
                                            if (r <= 0.18414215743541718f) {
                                                return true;
                                            } else {
                                                return false;
                                            }
                                        } else {
                                            return true;
                                        }
                                    }
                                } else {
                                    if (nir <= 0.2299898862838745f) {
                                        return true;
                                    } else {
                                        return false;
                                    }
                                }
                            }
                        } else {
                            if (swir <= 0.21403657644987106f) {
                                if (b <= 0.1926003247499466f) {
                                    return false;
                                } else {
                                    if (r <= 0.2012772262096405f) {
                                        return true;
                                    } else {
                                        return false;
                                    }
                                }
                            } else {
                                return false;
                            }
                        }
                    } else {
                        if (r <= 0.2583845853805542f) {
                            if (swir <= 0.16916587203741074f) {
                                if (swir <= 0.13563881814479828f) {
                                    if (b <= 0.23381713777780533f) {
                                        if (r <= 0.1805218830704689f) {
                                            return false;
                                        } else {
                                            if (r <= 0.2278900444507599f) {
                                                return true;
                                            } else {
                                                return false;
                                            }
                                        }
                                    } else {
                                        if (r <= 0.22627928853034973f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    }
                                } else {
                                    if (nir <= 0.21636711806058884f) {
                                        if (b <= 0.21666181087493896f) {
                                            return true;
                                        } else {
                                            if (b <= 0.22506532818078995f) {
                                                if (r <= 0.19041138142347336f) {
                                                    return false;
                                                } else {
                                                    return true;
                                                }
                                            } else {
                                                return false;
                                            }
                                        }
                                    } else {
                                        if (r <= 0.18892355263233185f) {
                                            if (b <= 0.21948501467704773f) {
                                                if (nir <= 0.2926177382469177f) {
                                                    return true;
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                return false;
                                            }
                                        } else {
                                            if (r <= 0.24664689600467682f) {
                                                if (b <= 0.24001945555210114f) {
                                                    if (r <= 0.2325720116496086f) {
                                                        if (r <= 0.2055959329009056f) {
                                                            if (b <= 0.2226148396730423f) {
                                                                if (nir <= 0.29608336091041565f) {
                                                                    return true;
                                                                } else {
                                                                    return false;
                                                                }
                                                            } else {
                                                                if (nir <= 0.24444111436605453f) {
                                                                    return false;
                                                                } else {
                                                                    return true;
                                                                }
                                                            }
                                                        } else {
                                                            if (b <= 0.21460863947868347f) {
                                                                if (nir <= 0.2467319592833519f) {
                                                                    return true;
                                                                } else {
                                                                    return false;
                                                                }
                                                            } else {
                                                                return true;
                                                            }
                                                        }
                                                    } else {
                                                        if (b <= 0.23135944455862045f) {
                                                            return false;
                                                        } else {
                                                            return true;
                                                        }
                                                    }
                                                } else {
                                                    if (nir <= 0.24657293409109116f) {
                                                        if (r <= 0.22839190065860748f) {
                                                            return false;
                                                        } else {
                                                            return true;
                                                        }
                                                    } else {
                                                        if (r <= 0.22159968316555023f) {
                                                            if (nir <= 0.26167501509189606f) {
                                                                return false;
                                                            } else {
                                                                return true;
                                                            }
                                                        } else {
                                                            return true;
                                                        }
                                                    }
                                                }
                                            } else {
                                                if (b <= 0.23745397478342056f) {
                                                    return false;
                                                } else {
                                                    return true;
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (b <= 0.2268221080303192f) {
                                    if (r <= 0.22514289617538452f) {
                                        if (swir <= 0.2124999314546585f) {
                                            if (nir <= 0.24318204820156097f) {
                                                return true;
                                            } else {
                                                if (b <= 0.2057235687971115f) {
                                                    if (r <= 0.20751319825649261f) {
                                                        return true;
                                                    } else {
                                                        return false;
                                                    }
                                                } else {
                                                    if (nir <= 0.3267645835876465f) {
                                                        return true;
                                                    } else {
                                                        return false;
                                                    }
                                                }
                                            }
                                        } else {
                                            if (b <= 0.2112562507390976f) {
                                                if (nir <= 0.24015408009290695f) {
                                                    return true;
                                                } else {
                                                    return false;
                                                }
                                            } else {
                                                return true;
                                            }
                                        }
                                    } else {
                                        if (r <= 0.23578332364559174f) {
                                            if (b <= 0.2133011370897293f) {
                                                return false;
                                            } else {
                                                return true;
                                            }
                                        } else {
                                            return false;
                                        }
                                    }
                                } else {
                                    if (nir <= 0.3551904559135437f) {
                                        if (swir <= 0.18531618267297745f) {
                                            if (nir <= 0.3108386993408203f) {
                                                return true;
                                            } else {
                                                return false;
                                            }
                                        } else {
                                            return true;
                                        }
                                    } else {
                                        if (swir <= 0.20792880654335022f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (b <= 0.24988262355327606f) {
                                return false;
                            } else {
                                if (r <= 0.2778242379426956f) {
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    }
                } else {
                    if (b <= 0.22468672692775726f) {
                        if (b <= 0.21358995884656906f) {
                            return false;
                        } else {
                            if (nir <= 0.2738629877567291f) {
                                return true;
                            } else {
                                if (r <= 0.23155757039785385f) {
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    } else {
                        if (r <= 0.2722383141517639f) {
                            if (b <= 0.24431665986776352f) {
                                if (nir <= 0.29368163645267487f) {
                                    return true;
                                } else {
                                    return false;
                                }
                            } else {
                                return true;
                            }
                        } else {
                            if (b <= 0.25501789152622223f) {
                                return false;
                            } else {
                                if (r <= 0.28636857867240906f) {
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        if (swir <= 0.15164829790592194f) {
            if (swir <= 0.13042839616537094f) {
                if (swir <= 0.11416876316070557f) {
                    return false;
                } else {
                    if (nir <= 0.3410834074020386f) {
                        if (r <= 0.249460868537426f) {
                            return false;
                        } else {
                            if (b <= 0.28611600399017334f) {
                                if (nir <= 0.29978735744953156f) {
                                    return true;
                                } else {
                                    return false;
                                }
                            } else {
                                if (r <= 0.2750682383775711f) {
                                    return false;
                                } else {
                                    if (b <= 0.3050225079059601f) {
                                        if (swir <= 0.12240461260080338f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    } else {
                                        return false;
                                    }
                                }
                            }
                        }
                    } else {
                        return false;
                    }
                }
            } else {
                if (nir <= 0.2636381685733795f) {
                    return false;
                } else {
                    if (b <= 0.3767738342285156f) {
                        if (swir <= 0.13971594721078873f) {
                            if (b <= 0.27920936048030853f) {
                                if (r <= 0.24487118422985077f) {
                                    return false;
                                } else {
                                    return true;
                                }
                            } else {
                                if (r <= 0.27748778462409973f) {
                                    return false;
                                } else {
                                    if (b <= 0.30443213880062103f) {
                                        return true;
                                    } else {
                                        if (r <= 0.3059317171573639f) {
                                            return false;
                                        } else {
                                            return true;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (b <= 0.2916194498538971f) {
                                if (r <= 0.24498550593852997f) {
                                    return false;
                                } else {
                                    return true;
                                }
                            } else {
                                if (r <= 0.29602184891700745f) {
                                    return false;
                                } else {
                                    return true;
                                }
                            }
                        }
                    } else {
                        return true;
                    }
                }
            }
        } else {
            if (swir <= 0.16261164844036102f) {
                if (nir <= 0.2706031799316406f) {
                    return false;
                } else {
                    if (r <= 0.3797828406095505f) {
                        return true;
                    } else {
                        return false;
                    }
                }
            } else {
                if (b <= 0.29708558320999146f) {
                    if (r <= 0.3054882735013962f) {
                        if (nir <= 0.2734023928642273f) {
                            return true;
                        } else {
                            if (r <= 0.2905828505754471f) {
                                return true;
                            } else {
                                if (b <= 0.27066099643707275f) {
                                    return false;
                                } else {
                                    return true;
                                }
                            }
                        }
                    } else {
                        if (b <= 0.28413522243499756f) {
                            return false;
                        } else {
                            if (r <= 0.319858118891716f) {
                                return true;
                            } else {
                                return false;
                            }
                        }
                    }
                } else {
                    return true;
                }
            }
        }
    }
}
