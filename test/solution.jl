using Test
using OrdinaryDiffEq
using DiffEqProblemLibrary.ODEProblemLibrary: importodeproblems; importodeproblems()
import DiffEqProblemLibrary.ODEProblemLibrary: prob_ode_linear, prob_ode_2Dlinear, prob_ode_lotkavoltera, prob_ode_fitzhughnagumo
using Measurements
using ModelingToolkit

import ProbNumODE: plot_stepsizes, plot_sigmas, plot_residuals, plot_errors, plot_calibration


@testset "Solution" begin
    prob = prob_ode_lotkavoltera
    sol = solve(prob, EKF0(), steprule=:constant, dt=1e-2)

    @test length(sol) > 2
    @test length(sol.t) == length(sol.u)
    @test length(prob.u0) == length(sol.u[end])

    # Destats
    @testset "DEStats" begin
        @test length(sol.t) == sol.destats.naccept
        @test sol.destats.naccept <= sol.destats.nf
    end

    @testset "Call on known t" begin
        @test sol.(sol.t) == sol.u
        u0 = sol(prob.tspan[1])
        @test prob.u0 == u0.μ
        @test all(u0.Σ .== 0)
    end

    # Interpolation
    @testset "Dense Solution" begin
        t0 = prob.tspan[1]
        t1, t2 = t0 + 1e-2, t0 + 2e-2
        u0, u1, u2 = sol(t0), sol(t1), sol(t2)
        @test norm.(u0.μ - u1.μ) < norm.(u0.μ - u2.μ)
        @test all(diag(u1.Σ) .< diag(u2.Σ))
    end

    @testset "Plotting" begin
        @test plot(sol) isa Plots.Plot
        @test plot_stepsizes(sol) isa Plots.Plot
        @test plot_sigmas(sol) isa Plots.Plot
        @test plot_residuals(sol) isa Plots.Plot

        sol2 = solve(prob, Tsit5(), abstol=1e-10, reltol=1e-10)
        @test plot_errors(sol, sol2) isa Plots.Plot
        @test plot_calibration(sol, sol2) isa Plots.Plot
    end
end