using PowerDynamics: SlackAlgebraic, SwingEqLVS, PQAlgebraic, StaticLine, PowerGrid, find_operationpoint, VSIMinimal, power_flow
using OrderedCollections:OrderedDict
using Test: @test, @testset, @test_throws, @test_logs, @test_nowarn

node_dict=OrderedDict(
    "bus1"=>SlackAlgebraic(U=1.),
    "bus2"=>SwingEqLVS(H=5., P=1., D=0.1, Ω=50,Γ=0.1,V=1.),
    "bus3"=>SwingEqLVS(H=5., P=1., D=0.1, Ω=50,Γ=0.1,V=1.),#VSIMinimal(τ_P=1., τ_Q=2., K_P=3., K_Q=4., V_r=1, P=1., Q=0.),
    "bus4"=> PQAlgebraic(P=-1,Q=-1)) #note - for PowerModels it is different default direction, multiply by -1

line_dict=OrderedDict(
    "line1" => StaticLine(from="bus1",to="bus2",Y=-1im/0.02),
    "line2" => StaticLine(from="bus2",to="bus3",Y=-1im/0.02),
    "line3" => StaticLine(from="bus3",to="bus4",Y=-1im/0.02))

node_list=[]
    append!(node_list, [SlackAlgebraic(U=1.)])
    append!(node_list, [SwingEqLVS(H=5., P=1., D=0.1, Ω=50,Γ=0.1,V=1.)])
    append!(node_list, [SwingEqLVS(H=5., P=1., D=0.1, Ω=50,Γ=0.1,V=1.)])
    append!(node_list, [PQAlgebraic(P=-1,Q=-1)])

line_list=[]
    append!(line_list,[StaticLine(from=1,to=2,Y=-1im/0.02)])
    append!(line_list,[StaticLine(from=2,to=3,Y=-1im/0.02)])
    append!(line_list,[StaticLine(from=3,to=4,Y=-1im/0.02)])

powergrid_dict = PowerGrid(node_dict,line_dict)
powergrid=PowerGrid(node_list,line_list)

##

operationpoint = find_operationpoint(powergrid)

data, result = power_flow(powergrid)

data_2, result_2 = power_flow(powergrid_dict)

N = length(node_list)

v = [result["solution"]["bus"][string(k)]["vm"] for k in 1:N]
v_2 = v = [result_2["solution"]["bus"][string(k)]["vm"] for k in 1:N]


println(operationpoint[:, :v]-v)
println(operationpoint[:, :v]-v_2)
println(isapprox.(operationpoint[:, :v], v, atol=1e-10) |> all)

@test isapprox.(operationpoint[:, :v], v, atol=1e-4) |> all

va = [result["solution"]["bus"][string(k)]["va"] for k in 1:N]
va_2 = [result_2["solution"]["bus"][string(k)]["va"] for k in 1:N]


println(operationpoint[:, :φ]-va)
println(operationpoint[:, :φ]-va_2)
@test isapprox.(operationpoint[:, :φ], va, atol=1e-10) |> all

p = [result["solution"]["gen"][string(k)]["pg"] for k in 1:N-1]

@test isapprox.(operationpoint[1:N-1, :p], p, atol=1e-10) |> all

q = [result["solution"]["gen"][string(k)]["qg"] for k in 1:N-1]

@test isapprox.(operationpoint[1:N-1, :q], q, atol=1e-10) |> all
    